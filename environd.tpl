<html>
	<head>
		<title>RPi Environd Sensor</title>
	</head>
	<body>
		<content>
			<p>
				The temperature is currently: {last_point_temp}
				<br/>
				Last Checked {last_point_datetime}
			</p>
			<p>
				<canvas id="myChart" width="1024" height="300"></canvas>
			</p>
		</content>
	</body>
	<script src="Chart.min.js"></script>
	<script>
		var data = {{
			labels: {graph_recent_xvals},
			datasets: [
				{{
					label: "Temperature",
					fillColor: "rgba(151,187,205,0.2)",
					strokeColor: "rgba(151,187,205,1)",
					pointColor: "rgba(151,187,205,1)",
					pointStrokeColor: "#fff",
					pointHighlightFill: "#fff",
					pointHighlightStroke: "rgba(151,187,205,1)",
					data: {graph_recent_yvals}
				}},
			]
		}};
		var options = {{
			///Boolean - Whether grid lines are shown across the chart
			scaleShowGridLines : true,

			//String - Colour of the grid lines
			scaleGridLineColor : "rgba(0,0,0,.05)",

			//Number - Width of the grid lines
			scaleGridLineWidth : 1,

			//Boolean - Whether to show horizontal lines (except X axis)
			scaleShowHorizontalLines: true,

			//Boolean - Whether to show vertical lines (except Y axis)
			scaleShowVerticalLines: true,

			//Boolean - Whether the line is curved between points
			bezierCurve : true,

			//Number - Tension of the bezier curve between points
			bezierCurveTension : 0.4,

			//Boolean - Whether to show a dot for each point
			pointDot : true,

			//Number - Radius of each point dot in pixels
			pointDotRadius : 4,

			//Number - Pixel width of point dot stroke
			pointDotStrokeWidth : 1,

			//Number - amount extra to add to the radius to cater for hit detection outside the drawn point
			pointHitDetectionRadius : 20,

			//Boolean - Whether to show a stroke for datasets
			datasetStroke : true,

			//Number - Pixel width of dataset stroke
			datasetStrokeWidth : 2,

			//Boolean - Whether to fill the dataset with a colour
			datasetFill : true,

			//String - A legend template
			legendTemplate : "<ul class=\"<%=name.toLowerCase()%>-legend\"><% for (var i=0; i<datasets.length; i++){{%><li><span style=\"background-color:<%=datasets[i].lineColor%>\"></span><%if(datasets[i].label){{%><%=datasets[i].label%><%}}%></li><%}}%></ul>"

		}}
		var ctx = document.getElementById("myChart").getContext("2d");
		var myLineChart = new Chart(ctx).Line(data, options);
	</script>
</html>

