{GreenButton} = require "../lib/sdk"

module.exports = (req, res) ->
  
  doRender = (err, data) ->
    if err
      req.flash "error", err
    else if data
      multiplier = data.usageSummary.powerOfTenMultiplier
      timestamps= []
      usage= []
      costs= []
      console.log 'hello', data
      for block in data.intervalBlock.intervalBlocks
        #console.log block
        for reading in block.intervalReadings
          console.log reading.timePeriod.start
          console.log reading.value
          console.log reading.cost
          timestamps.push reading.timePeriod.start
          usage.push reading.value
          costs.push reading.cost
          data = JSON.stringify
            chartCosts:costs
            chartTimestamps:timestamps
            chartUsage:usage

    res.render "home", {data: data}
    
  if req.session.user
    GreenButton(req).load doRender
  else
    doRender()


