const cds = require('@sap/cds')

module.exports = cds.service.impl(function () {

  const { Configuration, Cars, Rentals, Maintenance, Customers, Category } = this.entities

  // ── Validates start/end dates: both required, start ≤ end ──
  const validateDates = (start, end, req) => {
    if (!start || !end) req.reject(400, 'Start and End date are required')
    if (new Date(start) > new Date(end)) req.reject(400, 'Start date must be before or equal to End date')
  }

  // ── Rejects if car has overlapping Rental or Maintenance in given period ──
  const checkOverlap = async (car_licensePlate, start, end, req) => {
    const where = {
      car_licensePlate,
      startDate: { '<=': end },
      endDate  : { '>=': start }
    }
    const rental      = await SELECT.one.from(Rentals).where(where)
    const maintenance = await SELECT.one.from(Maintenance).where(where)

    if (rental) {
      console.warn(`[OVERLAP] Car ${car_licensePlate} already rented | Conflicting Rental: ${rental.ID}`)
      req.reject(409, 'Car is already rented in this period')
    }
    if (maintenance) {
      console.warn(`[OVERLAP] Car ${car_licensePlate} under maintenance | Conflicting Maintenance: ${maintenance.ID}`)
      req.reject(409, 'Car is under maintenance in this period')
    }
  }

  // ── Car CREATE/UPDATE: validate year, price, category ──
  this.before(['CREATE', 'UPDATE'], Cars, async req => {
    const { year, dailyPrice, category_code } = req.data
    const currentYear = new Date().getFullYear()

    if (year !== undefined && year > currentYear)
      req.reject(400, 'Year cannot be in the future')

    if (year !== undefined && year < currentYear - 15)
      req.reject(400, `Car must not be older than 15 years (year >= ${currentYear - 15})`)

    if (dailyPrice !== undefined && dailyPrice <= 0)
      req.reject(400, 'Daily price must be greater than 0')

    if (category_code) {
      const cat = await SELECT.one.from(Category).where({ code: category_code })
      if (!cat) {
        console.warn(`[VALIDATION] Category not found: ${category_code}`)
        req.reject(400, `Category "${category_code}" does not exist`)
      }
    }
  })

  // ── Block direct POST on Rentals — use rent action instead ──
  this.before('CREATE', Rentals, req => {
    console.warn('[BLOCKED] Direct POST on Rentals rejected')
    req.reject(405, "Use the 'rent' action to create Rentals")
  })

  // ── Block direct POST on Maintenance — use setToMaintenance instead ──
  this.before('CREATE', Maintenance, req => {
    console.warn('[BLOCKED] Direct POST on Maintenance rejected')
    req.reject(405, "Use the 'setToMaintenance' action to create Maintenance")
  })

  // ── Configuration singleton — returns logged-in user info for UI ──
  this.on('READ', 'Configuration', req => {
    return {
      ID     : 'singleton',
      userId : req.user.id,
      isAdmin: req.user.is('admin')
    }
  })

  // ── Populate virtual isAdmin field on Cars for role-based UI hiding ──
  this.after('READ', Cars, (data, req) => {
    const isAdmin = req.user.is('admin')
    if (Array.isArray(data)) data.forEach(car => car.isAdmin = isAdmin)
    else if (data) data.isAdmin = isAdmin
  })

  // ── rent action: validate → verify → overlap check → insert → emit event ──
  this.on('rent', 'Cars', async req => {
    const car_licensePlate = req.params[0].licensePlate
    const startDate        = req.data.startDate
    const endDate          = req.data.endDate
    const customer_ID      = req.user.is('admin') ? req.data.customer_ID : req.user.id

    console.log(`[RENT] Car: ${car_licensePlate} | Customer: ${customer_ID} | ${startDate} → ${endDate}`)

    validateDates(startDate, endDate, req)

    const car = await SELECT.one.from(Cars).where({ licensePlate: car_licensePlate })
    if (!car) req.reject(404, 'Car not found')

    const customer = await SELECT.one.from(Customers).where({ ID: customer_ID })
    if (!customer) req.reject(404, `Customer "${customer_ID}" not found`)

    await checkOverlap(car_licensePlate, startDate, endDate, req)

    const MS_PER_DAY = 1000 * 60 * 60 * 24
    const days       = Math.ceil((new Date(endDate) - new Date(startDate)) / MS_PER_DAY) + 1
    const totalPrice = days * car.dailyPrice

    console.log(`[RENT] Total price: ${days} days × ${car.dailyPrice} = ${totalPrice}`)

    await INSERT.into(Rentals).entries({ startDate, endDate, totalPrice, customer_ID, car_licensePlate })

    const created = await SELECT.one.from(Rentals).where({ car_licensePlate, customer_ID, startDate, endDate })

    await this.emit('Rental.Created', created)

    // Notify user if auto maintenance threshold reached
    const twelveMonthsAgo = new Date()
    twelveMonthsAgo.setFullYear(twelveMonthsAgo.getFullYear() - 1)
    const rentalCount = await SELECT.from(Rentals).where({
      car_licensePlate,
      startDate: { '>=': twelveMonthsAgo.toISOString().split('T')[0] }
    })
    if (rentalCount.length >= 10) {
      req.info('Auto maintenance scheduled due to high usage')
    }

    console.log(`[RENT] Completed — Rental ID: ${created.ID}`)
    return created
  })

  // ── Rental.Created: if car has 10+ rentals in 12 months → auto maintenance ──
  this.on('Rental.Created', async event => {
    const rental = event.data

    const twelveMonthsAgo = new Date()
    twelveMonthsAgo.setFullYear(twelveMonthsAgo.getFullYear() - 1)
    const fromDate = twelveMonthsAgo.toISOString().split('T')[0]

    const rentals = await SELECT.from(Rentals).where({
      car_licensePlate: rental.car_licensePlate,
      startDate       : { '>=': fromDate }
    })

    console.log(`[AUTO-MAINTENANCE] Car: ${rental.car_licensePlate} | Rentals in last 12 months: ${rentals.length}`)

    if (rentals.length >= 10) {
      const start = new Date(rental.endDate)
      start.setDate(start.getDate() + 1)
      const startDate = start.toISOString().split('T')[0]

      const end = new Date(start)
      end.setDate(end.getDate() + 1)
      const endDate = end.toISOString().split('T')[0]

      await INSERT.into(Maintenance).entries({
        startDate,
        endDate,
        description    : '[Auto] Scheduled maintenance after high usage',
        cost           : 0,
        car_licensePlate: rental.car_licensePlate
      })

      console.log(`[AUTO-MAINTENANCE] Created for Car: ${rental.car_licensePlate} | ${startDate} → ${endDate}`)
    }
  })

  // ── setToMaintenance: validate → verify → overlap check → insert ──
  this.on('setToMaintenance', 'Cars', async req => {
    const car_licensePlate              = req.params[0].licensePlate
    const { startDate, endDate, description, cost } = req.data

    console.log(`[MAINTENANCE] Car: ${car_licensePlate} | ${startDate} → ${endDate} | Cost: ${cost}`)

    validateDates(startDate, endDate, req)

    const car = await SELECT.one.from(Cars).where({ licensePlate: car_licensePlate })
    if (!car) req.reject(404, 'Car not found')

    await checkOverlap(car_licensePlate, startDate, endDate, req)

    await INSERT.into(Maintenance).entries({ startDate, endDate, description, cost, car_licensePlate })

    const created = await SELECT.one.from(Maintenance).where({ car_licensePlate, startDate, endDate, description })

    console.log(`[MAINTENANCE] Completed — Maintenance ID: ${created.ID}`)
    return created
  })

  // ── Recalculate totalPrice on READ if not already stored ──
  this.after('READ', Rentals, async (data) => {
    const calc = async (r) => {
      if (!r || !r.startDate || !r.endDate || r.totalPrice) return
      const car = await SELECT.one.from(Cars).where({ licensePlate: r.car_licensePlate })
      if (!car) return
      const MS_PER_DAY = 1000 * 60 * 60 * 24
      const days       = Math.ceil((new Date(r.endDate) - new Date(r.startDate)) / MS_PER_DAY) + 1
      r.totalPrice     = days * car.dailyPrice
    }
    if (Array.isArray(data)) for (const r of data) await calc(r)
    else await calc(data)
  })

})