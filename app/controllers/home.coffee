{GreenButton} = require "../lib/sdk"

module.exports = (req, res) ->
  
  doRender = (err, data) ->
    if err
      req.flash "error", err
    else if data
      multiplier = data.usageSummary.powerOfTenMultiplier or 3
      divisor = Math.pow(10,multiplier)
      timestamps= []
      usage= []
      costs= []
      for block in data.intervalBlock.intervalBlocks
        for reading in block.intervalReadings
          timestamps.push reading.timePeriod.start
          usage.push parseFloat(reading.value)/divisor
          costs.push reading.cost
      data= JSON.stringify
        chartCosts:costs
        chartTimestamps:timestamps
        chartUsage:usage
        multiplier:multiplier

    res.render "home", {data: data}
    
  if req.session.user
    GreenButton(req).load doRender
  else
    doRender()


