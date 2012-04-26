$(document).ready(function(){
  var myData = $("#chartData").html();
  var chartData = JSON.parse(myData);
  var overview;
  var plot;
  var updateLegendTimeout = null;
  var latestPosition = null;
  var legends;
  var allUsage = [];
  var allCosts = [];
  var recentUsage = [];
  var recentCosts = [];
  var recentDataDaysAgo = 7;
  
  //Base chart options
  var options = {
    legend: { show: true } , 
    xaxes: [ { mode: "time", position: "top"}],
    yaxes: [ { min: 0, tickDecimals: 3 },{ position: "right"} ],
    selection: { mode: "x"},
    series: {
      lines: { show: true },
      points: { show: true }
    },
    grid: { hoverable: true, clickable: true },
    crosshair: { mode: "x" }    
  };

    //Data chart option for ALL cost and consumption data.
    function getAllData() {
       return [ { data: allUsage, label: "kWh" }, 
                { data: allCosts, label: "USD", yaxis: 2 } ];
    }
    
    //Data chart option for data going back to only 'recentDaysAgo' value.
    function getRecentData() {
      return [ { data: recentUsage, label: "kWh" }, 
              { data: recentCosts, label: "USD", yaxis: 2 } ];
    }
    
    //Plot the overview navigation chart associated with the main chart.
    function setupOverview() {
      overview = $.plot($("#overview"), 
         getAllData(), 
         {
          legend: { show: true, container: $("#overviewLegend") },
          series: {
              lines: { show: true, lineWidth: 1 },
              shadowSize: 0
          },
          xaxes: [ { mode: "time" }],
          yaxes: [ { show: false }, {show: false}],
          grid: { color: "#999" },
          selection: { mode: "x" }
      });
    }
    
    //Plot the main chart.
    function setupMainPlot() {
      plot = $.plot($("#placeholder"), 
             getRecentData(), 
             options 
      );
    }
    
    //Prepare the legends (if any)
    function setLegends() {
      legends = $("#placeholder .legendLabel");
      legends.each(function () {
          // fix the widths so they don't jump around
          $(this).css('width', $(this).width);
      });
    }
    
    //Update the legends in conjunction with crosshair movement.
    function updateLegend() {
            updateLegendTimeout = null;

            var pos = latestPosition;

            var axes = plot.getAxes();
            if (pos.x < axes.xaxis.min || pos.x > axes.xaxis.max ||
                pos.y < axes.yaxis.min || pos.y > axes.yaxis.max)
                return;

            var i, j, dataset = plot.getData();
            for (i = 0; i < dataset.length; ++i) {
                var series = dataset[i];

                // find the nearest points, x-wise
                for (j = 0; j < series.data.length; ++j)
                    if (series.data[j][0] > pos.x)
                        break;

                // now interpolate
                var y, p1 = series.data[j - 1], p2 = series.data[j];
                if (p1 == null)
                    y = p2[1];
                else if (p2 == null)
                    y = p1[1];
                else
                    y = p1[1] + (p2[1] - p1[1]) * (pos.x - p1[0]) / (p2[0] - p1[0]);
                legends.eq(i).text(y.toFixed(2) + " " + series.label);
            }
        }

     //Prepare the datta for chart use.
    function initializeChartData() {
      var count = chartData.chartTimestamps.length;
      var oneWeekAgo = (recentDataDaysAgo).days().ago();
      var recentStartIndex = -1;
      for ( i = 0 ; i < count ; i++ ) {
        allUsage[i] = [chartData.chartTimestamps[i]*1000,parseFloat(chartData.chartUsage[i])];
        allCosts[i] = [chartData.chartTimestamps[i]*1000, chartData.chartCosts[i]/100000];
      
        if ( recentStartIndex == -1  && oneWeekAgo <= allUsage[i][0]) {
           //add to recentUsage and recentCosts arrays
           recentStartIndex = i;
        }        
      }
      
      if ( recentStartIndex != -1 ) {
        for ( j = recentStartIndex ; j < count ; j++ ) {
          recentUsage[j-recentStartIndex] = allUsage[j];
          recentCosts[j-recentStartIndex] = allCosts[j]; 
        }
      }
      
      else {
        recentUsage = allUsage;
        recentCosts = allCosts;
      }
    }


    //Connect the navigation chart to the main chart.
    $("#placeholder").bind("plotselected", function (event, ranges) {
        // clamp the zooming to prevent eternal zoom
        if (ranges.xaxis.to - ranges.xaxis.from < 0.00001)
            ranges.xaxis.to = ranges.xaxis.from + 0.00001;
        if (ranges.yaxis.to - ranges.yaxis.from < 0.00001)
         ranges.yaxis.to = ranges.yaxis.from + 0.00001;
    
        // do the zooming
        plot = $.plot($("#placeholder"), getAllData(),
                      $.extend(true, {}, options, {
                          xaxes: [{ min: ranges.xaxis.from, max: ranges.xaxis.to }, { mode: "time" }, { position: "top"}],
                          yaxes: [{ min: 0 }, {position: "right"}]
                      }));
        setLegends();

        // don't fire event on the overview to prevent eternal loop
        overview.setSelection(ranges, true);
    });
    
    $("#overview").bind("plotselected", function (event, ranges) {
        plot.setSelection(ranges);
    });

    //Tooltip formatting.
    function showTooltip(x, y, contents, color) {
            $('<div id="tooltip">' + contents + '</div>').css( {
                position: 'absolute',
                display: 'none',
                top: y + 5,
                left: x + 5,
                border: '1px solid black',
                padding: '2px',
                'background-color': color,
                opacity: 0.80
            }).appendTo("body").fadeIn(200);
    }

        
    var previousPoint = null;

    //Handle crosshair movement in response to mouse hover.  
    $("#placeholder").bind("plothover", function (event, pos, item) {
        $("#x").text(pos.x.toFixed(2));
        $("#y").text(pos.y.toFixed(2));
        if (item) {
          if (previousPoint != item.datapoint) {
              previousPoint = item.datapoint;

              $("#tooltip").remove();
              var x = item.datapoint[0].toFixed(2),
              y = item.datapoint[1].toFixed(2);
              
              var tipString;
              d = new Date(Math.floor(x));
              tipString = "Date: " + d.toString('MMMM dd, HH:mm') + "<br>";
              if ( item.seriesIndex == 0 ) {
                tipString += y + " kWh";
              }
              else
              {
                tipString += y + " USD";
              }
              
              showTooltip(item.pageX, item.pageY, tipString, item.series.color);
              }
          }
          else {
             $("#tooltip").remove();
                previousPoint = null;
          }
          
          latestPosition = pos;
          if (!updateLegendTimeout)
              updateLegendTimeout = setTimeout(updateLegend, 50);
    });
        
    
    //Refresh the main chart to 'recentDaysAgo' data upon double click.    
    $('#placeholder').dblclick(function() {
      setupMainPlot();
      setLegends();
      setupOverview();
    });
        
        
/********************************************************************************************************
 *   Go do it!
 ********************************************************************************************************/
   initializeChartData();
   setupMainPlot();
   setupOverview();    
   setLegends();
});