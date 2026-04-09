const cds = require('@sap/cds')

module.exports = cds.service.impl(function () {

  const { Configuration, Cars, Rentals, Maintenance, Customers, Category } = this.entities

  // DATE VALIDATION                       
  const validateDates = (start, end, req) => {

    if (!start || !end) {
      req.reject(400, "Start and End date are required")
    }

    if (new Date(start) > new Date(end)) {
      req.reject(400, "Start date must be before or equal to End date")
    }

    console.log("✅ Dates are valid")
  }

  /* ===================================== */
  /* OVERLAP CHECK                         */
  /* Checks BOTH Rentals AND Maintenance   */
  /* Accepts optional excludeId for UPDATE */
  /* ===================================== */
  const checkOverlap = async (car_licensePlate, start, end, req, excludeId = null) => {

    // Build rental overlap query
    const rentalWhere = {
      car_licensePlate,
      startDate: { '<=': end },
      endDate: { '>=': start }
    }

    // Build maintenance overlap query
    const maintWhere = {
      car_licensePlate,
      startDate: { '<=': end },
      endDate: { '>=': start }
    }

    let rental = await SELECT.one.from(Rentals).where(rentalWhere)
    let maintenance = await SELECT.one.from(Maintenance).where(maintWhere)

    // For UPDATE: exclude the record being updated from the overlap check
    if (excludeId) {
      if (rental && rental.ID === excludeId) rental = null
      if (maintenance && maintenance.ID === excludeId) maintenance = null
    }

    if (rental) {
      console.error("Car is already rented in this period")
      req.reject(409, "Car is already rented in this period")
    }

    if (maintenance) {
      console.error("Car is under maintenance in this period")
      req.reject(409, "Car is under maintenance in this period")
    }

    console.log("✅ No overlap found")
  }

  /* ===================================== */
  /* CAR VALIDATIONS (CREATE + UPDATE)     */
  /* ===================================== */
  this.before(['CREATE', 'UPDATE'], Cars, async req => {
    console.log("CAR VALIDATION on Create and Update :  Req data:", req.data)

    const { year, dailyPrice, category_code } = req.data
    const currentYear = new Date().getFullYear()

    // Year must not be in the future
    if (year !== undefined && year > currentYear) {
      console.error("❌ Year is in the future")
      req.reject(400, "Year cannot be in the future")
    }

    // Year must be within last 15 years
    if (year !== undefined && year < currentYear - 15) {
      console.error("❌ Car is too old")
      req.reject(400, `Car must not be older than 15 years (year >= ${currentYear - 15})`)
    }

    // Daily price must be > 0
    if (dailyPrice !== undefined && dailyPrice <= 0) {
      console.error("❌ Invalid daily price")
      req.reject(400, "Daily price must be greater than 0")
    }

    // Category must exist in the Category entity
    if (category_code) {
      console.log("Checking category:", category_code)
      const cat = await SELECT.one.from(Category).where({ code: category_code })
      if (!cat) {
        console.error("❌ Category not found")
        req.reject(400, `Category "${category_code}" does not exist`)
      }
    }

    console.log("✅ Car validation passed")
  })

  /* ===================================== */
  /* BLOCK DIRECT CREATE ON RENTALS        */
  /* Use 'rent' action instead             */
  /* ===================================== */
  this.before('CREATE', Rentals, req => {
    console.warn("⚠️ Direct CREATE on Rentals blocked")
    req.reject(405, "Rentals cannot be created directly. Use the 'rent' action on a Car.")
  })

  /* ===================================== */
  /* BLOCK DIRECT CREATE ON MAINTENANCE    */
  /* Use 'setToMaintenance' action instead */
  /* ===================================== */
  this.before('CREATE', Maintenance, req => {
    console.warn("⚠️ Direct CREATE on Maintenance blocked")
    req.reject(405, "Maintenance cannot be created directly. Use the 'setToMaintenance' action on a Car.")
  })

  /* ===================================== */
  /* RENTAL UPDATE VALIDATION              */
  /* ===================================== */
  this.before('UPDATE', Rentals, async req => {
    console.log("Before Update Rental : ", req.data)

    // Fetch existing record to fill in any missing fields from the PATCH payload
    const existing = await SELECT.one.from(Rentals).where({ ID: req.params[0] })
    if (!existing) return

    const startDate = req.data.startDate ?? existing.startDate
    const endDate = req.data.endDate ?? existing.endDate
    const car_licensePlate = req.data.car_licensePlate ?? existing.car_licensePlate

    validateDates(startDate, endDate, req)

    // Pass existing.ID so the overlap check ignores this record itself
    await checkOverlap(car_licensePlate, startDate, endDate, req, existing.ID)
  })

  /* ===================================== */
  /* MAINTENANCE UPDATE VALIDATION         */
  /* ===================================== */
  this.before('UPDATE', Maintenance, async req => {
    console.log("Before Update Maintenance", req.data)

    // Fetch existing record to fill in any missing fields from the PATCH payload
    const existing = await SELECT.one.from(Maintenance).where({ ID: req.params[0] })
    if (!existing) return

    const startDate = req.data.startDate ?? existing.startDate
    const endDate = req.data.endDate ?? existing.endDate
    const car_licensePlate = req.data.car_licensePlate ?? existing.car_licensePlate

    validateDates(startDate, endDate, req)

    // Pass existing.ID so the overlap check ignores this record itself
    await checkOverlap(car_licensePlate, startDate, endDate, req, existing.ID)
  })

  //CONFIGURATION SINGLETON            
  // Returns Current User Info
  this.on('READ', 'Configuration', req => {
    return {
      ID: 'singleton',
      userId: req.user.id,
      isAdmin: req.user.is('admin')
    }
  })
  // POPULATE isAdmin VIRTUAL FIELD     
  // Runs after every Cars READ         
  // Fiori uses this for UI hiding   
  this.after('READ', Cars, (data, req) => {
    const isAdmin = req.user.is('admin') === true ? true : false
    if (Array.isArray(data)) {
      data.forEach(car => car.isAdmin = isAdmin)
    } else if (data) {
      data.isAdmin = isAdmin
    }
  })

  /* ===================================== */
  /* 🔥 BOUND ACTION: RENT                 */
  /* Creates a Rental and returns it       */
  /* ===================================== */
  this.on('rent', 'Cars', async req => {
    console.log(" ===== RENT ACTION TRIGGERED =====")

    const car_licensePlate = req.params[0].licensePlate
    //const { startDate, endDate } = req.data
    startDate = req.data.startDate
    const endDate = req.data.endDate

    const customer_ID = req.user.is('admin') ? req.data.customer_ID : req.user.id

    console.log(" Car License Plate : ", car_licensePlate)
    console.log("Req Data in On rent handler : ", req.data)

    // Validate date range
    validateDates(startDate, endDate, req)

    // Verify car exists and get dailyPrice for totalPrice calculation
    const car = await SELECT.one.from(Cars).where({ licensePlate: car_licensePlate })
    if (!car) {
      console.error("❌ Car not found")
      req.reject(404, "Car not found (Rent Handler)")
    }

    const customer = await SELECT.one.from(Customers).where({ ID: customer_ID })
    if (!customer) {
      console.error("❌ Customer not found ( Rent Handler)")
      req.reject(404, `Customer "${customer_ID}" not found`)
    }

    //  Check no overlapping rental or maintenance period exists
    await checkOverlap(car_licensePlate, startDate, endDate, req)

    //  Calculate totalPrice = number of days (inclusive) × dailyPrice
    const MS_PER_DAY = 1000 * 60 * 60 * 24
    const days = Math.ceil((new Date(endDate) - new Date(startDate)) / MS_PER_DAY) + 1
    const totalPrice = days * car.dailyPrice
    console.log(` ${days} days × ${car.dailyPrice} = ${totalPrice}`)

    await INSERT.into(Rentals).entries({
      startDate,
      endDate,
      totalPrice,
      customer_ID,
      car_licensePlate
    })

    //  Return the newly created rental record
    const created = await SELECT.one.from(Rentals).where({
      car_licensePlate,
      customer_ID,
      startDate,
      endDate
    })
    // 🆕 emit Rental.Created event
    await this.emit('Rental.Created', created)

    console.log("✅ RENT SUCCESS:", created)
    return created
  })

  /* ===================================== */
  /* 🆕 EVENT: Rental.Created              */
  /* Auto-maintenance after 10 rentals     */
  /* ===================================== */
  this.on('Rental.Created', async event => {
    const rental = event.data
    console.log("📅 Rental.Created event:", rental)

    // count rentals for this car in last 12 months
    const twelveMonthsAgo = new Date()
    twelveMonthsAgo.setFullYear(twelveMonthsAgo.getFullYear() - 1)
    const fromDate = twelveMonthsAgo.toISOString().split('T')[0]

    const rentals = await SELECT.from(Rentals).where({
      car_licensePlate: rental.car_licensePlate,
      startDate: { '>=': fromDate }
    })

    console.log(`🔢 Rentals in last 12 months: ${rentals.length}`)

    if (rentals.length >= 3) {
      console.log("⚠️ High usage — creating auto maintenance")

      // start day after rental ends
      const start = new Date(rental.endDate)
      start.setDate(start.getDate() + 1)
      const startDate = start.toISOString().split('T')[0]

      // 1 day duration
      const end = new Date(start)
      end.setDate(end.getDate() + 1)
      const endDate = end.toISOString().split('T')[0]

      await INSERT.into(Maintenance).entries({
        startDate,
        endDate,
        description: '[Auto] Scheduled maintenance after high usage',
        cost: 0,
        car_licensePlate: rental.car_licensePlate
      })

      console.log("✅ Auto maintenance created:", startDate, "→", endDate)
    }
  })

  /* ===================================== */
  /* 🔥 BOUND ACTION: SET TO MAINTENANCE   */
  /* Creates a Maintenance record          */
  /* ===================================== */
  this.on('setToMaintenance', 'Cars', async req => {
    console.log(" ===== MAINTENANCE ACTION TRIGGERED =====")

    const car_licensePlate = req.params[0].licensePlate
    const { startDate, endDate, description, cost } = req.data

    console.log(" Car License Plate : ", car_licensePlate)
    console.log("Req Data (Maintenance Handler) : ", req.data)

    // Validate date range
    validateDates(startDate, endDate, req)

    //  Verify car exists
    const car = await SELECT.one.from(Cars).where({ licensePlate: car_licensePlate })
    if (!car) {
      console.error("❌ Car not found (Maintenance Handler) ")
      req.reject(404, "Car not found")
    }

    //  Check no overlapping rental or maintenance period exists
    await checkOverlap(car_licensePlate, startDate, endDate, req)

    //  Insert the maintenance record (cuid generates ID automatically)
    await INSERT.into(Maintenance).entries({
      startDate,
      endDate,
      description,
      cost,
      car_licensePlate
    })

    //  Return the newly created maintenance record
    const created = await SELECT.one.from(Maintenance).where({
      car_licensePlate,
      startDate,
      endDate,
      description
    })

    console.log("✅ MAINTENANCE SUCCESS:", created)
    return created
  })

  /* ===================================== */
  /* VIRTUAL FIELD: totalPrice on READ     */
  /* Recalculates if not stored in DB      */
  /* ===================================== */
  this.after('READ', Rentals, async (data) => {
    console.log("CALCULATE TOTAL PRICE..........")

    const calc = async (r) => {
      // Skip if totalPrice already set or dates/car missing
      if (!r || !r.startDate || !r.endDate || r.totalPrice) return

      const car = await SELECT.one.from(Cars).where({ licensePlate: r.car_licensePlate })
      if (!car) return

      const MS_PER_DAY = 1000 * 60 * 60 * 24
      const days = Math.ceil((new Date(r.endDate) - new Date(r.startDate)) / MS_PER_DAY) + 1
      r.totalPrice = days * car.dailyPrice

      console.log(`Rental ${r.ID} → ${days} days → ${r.totalPrice}`)
    }

    if (Array.isArray(data)) {
      for (const r of data) await calc(r)
    } else {
      await calc(data)
    }
  })

})