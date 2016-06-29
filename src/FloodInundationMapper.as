// 01.14.14 - NE - Handling for three sites library grid click. -->
// 08.16.12 - NE - Fix to gage values sorting. 
// 07.11.12 - NE - Edited to handle geocoder with appropriate error if nothing is entered.
// 07.11.12 - NE - Addition of counts for AHPS sites. Adjustments to AHPS forecast site info box. Removes box when corresponding site layer is toggled off.
// 07.10.12 - NE - Updated methods for displaying, toggling and querying AHPS forecast sites.
// 07.09.12 - NE - Edited code to handle fimi sites display and reduce errors.
// 03.26.12 - NE - Added the functionality to zoom to a site and automatically open the flood tools pop up when clicked on.
// 03.15.12 - NE- Updates for showing state and community rather than site no in flood tools and on site hover.
// 03.12.12 - NE - Updated to show tooltip texts for flood polygons with depth grid data available.
// 02.01.12 - NE - Added code to zoom to site from url parameters 'siteno' in url.
// 11.23.11 - NE - Tweaked grid query code.
// 11.22.11 - NE - Added code to appropriate show results of grid query.
// 11.21.11 - NE - Adding tracking for jobs so multiple graphics sets don't show.
// 11.16.11 - NE - Using unique depth range values for sites.
// 10.27.11 - NE - Breach handling tweaks.
// 06.14.11 - NE - Added grid confidence interval to water depth queries.
// 04.27.11 - NE - Added multi site capability.
// 12.3.10 - NE - Fixed bug with gridInfos length and onMapClick
// 12.2.10 - NE - Added right-click zoom out capability.
// 11.17.10 - NE - Updated for grid query capability. Added functionality to zoom to extent of flood graphics for site. Added loading message while flood graphics are returned to map.
// 11.15.10 - NE - Updated code to include handling of flood extents based on siteGraphic click and site number.  
// 11.9.10 - NE - Moved much of flood tools functionality to FloodToolsWindow component mxml file.
// 06.28.10 - JB - Added new Wim LayerLegend component
// 03.26.10 - JB - Created
/***
 * ActionScript file for Flood Inundation Mapper */

	import com.esri.ags.FeatureSet;
	import com.esri.ags.Graphic;
	import com.esri.ags.events.ExtentEvent;
	import com.esri.ags.events.FindEvent;
	import com.esri.ags.events.GraphicEvent;
	import com.esri.ags.events.MapMouseEvent;
	import com.esri.ags.events.PrintEvent;
	import com.esri.ags.geod.CoordinateTransformation;
	import com.esri.ags.geod.GeographicCS;
	import com.esri.ags.geod.ProjectedCS;
	import com.esri.ags.geod.ReferencedCS;
	import com.esri.ags.geod.Utilities;
	import com.esri.ags.geod.geom.MoreUtils;
	import com.esri.ags.geod.proj.GeographicProjection;
	import com.esri.ags.geod.proj.Mercator;
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.geometry.MapPoint;
	import com.esri.ags.layers.ArcGISDynamicMapServiceLayer;
	import com.esri.ags.layers.TiledMapServiceLayer;
	import com.esri.ags.symbols.InfoSymbol;
	import com.esri.ags.tasks.FindTask;
	import com.esri.ags.tasks.IdentifyTask;
	import com.esri.ags.tasks.PrintTask;
	import com.esri.ags.tasks.QueryTask;
	import com.esri.ags.tasks.supportClasses.AddressCandidate;
	import com.esri.ags.tasks.supportClasses.AddressToLocationsParameters;
	import com.esri.ags.tasks.supportClasses.DataFile;
	import com.esri.ags.tasks.supportClasses.FindParameters;
	import com.esri.ags.tasks.supportClasses.FindResult;
	import com.esri.ags.tasks.supportClasses.IdentifyParameters;
	import com.esri.ags.tasks.supportClasses.IdentifyResult;
	import com.esri.ags.tasks.supportClasses.JobInfo;
	import com.esri.ags.tasks.supportClasses.ParameterValue;
	import com.esri.ags.tasks.supportClasses.Query;
	import com.esri.ags.utils.WebMercatorUtil;
	import com.esri.agsx.geom.GeometryUtils;
	
	import controls.skins.WiMInfoWindowSkin;
	
	import flash.display.Graphics;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.*;
	
	import flashx.textLayout.events.UpdateCompleteEvent;
	
	import gov.usgs.wim.controls.WiMInfoWindow;
	import gov.usgs.wim.utils.XmlResourceLoader;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.controls.*;
	import mx.core.Application;
	import mx.core.FlexGlobals;
	import mx.core.IFlexDisplayObject;
	import mx.effects.Glow;
	import mx.events.CloseEvent;
	import mx.events.DropdownEvent;
	import mx.events.FlexEvent;
	import mx.events.StateChangeEvent;
	import mx.managers.BrowserManager;
	import mx.managers.IBrowserManager;
	import mx.managers.PopUpManager;
	import mx.resources.ResourceBundle;
	import mx.rpc.AsyncResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.utils.ObjectProxy;
	import mx.utils.StringUtil;
	import mx.utils.URLUtil;
	import mx.utils.object_proxy;
	
	import spark.components.TitleWindow;
	
	
	
	[Bindable]
	private var genAlpha:Number = 0.6;
	[Bindable]
	private var mapX:Number = 0;
	[Bindable]
	private var mapY:Number = 0;

	[Bindable]
	public var initMapExtent:Extent;
	
	public var siteX:Number;
	public var siteY:Number;
	
	private var siteExisting:Object = new Object();
	private var floodExisting:Object = new Object();
	
	//private var siteInfoWindowRenderer:ClassFactory = new ClassFactory(SiteInfoWindowRenderer);
	
	[Bindable]
	private var layerExpsMaxHeight:Number;
	[Bindable]
	private var transLayer:String = "";

	[Bindable]
	public var siteFID:String;
	[Bindable]
	public var siteNo:String;
	[Bindable]
	public var siteNo_2:String;
	[Bindable]
	public var siteNo_3:String;
	[Bindable]
	public var ahpsID:String;
	[Bindable]
	public var ahpsID_2:String;
	[Bindable]
	public var multiSite:String;

	[Bindable]
	public var currentStage:String;
	[Bindable]
	public var currentElev:String;
	[Bindable]
	public var currentDischarge:String;

	[Bindable]
	public var siteState:String;
	[Bindable]
	public var siteCommunity:String;
	[Bindable]
	public var authors:String;
	[Bindable]
	public var rep_date:String;
	[Bindable]
	public var title:String;
	[Bindable]
	public var rep_series:String;
	[Bindable]
	public var series_num:String;
	[Bindable]
	public var add_info:String;
	[Bindable]
	public var study_date:String;
	[Bindable]
	public var grid_serv:String;

	[Bindable]
	public var currentShortName:String;
	[Bindable]
	public var currentShortNames:Array;
	[Bindable]
	private var currentRepLink:String = null;
	[Bindable]
	private var currentReport:String = null;
	[Bindable]
	private var depthRange:String = null;
	

	private var mouseDiffX:Number;
	private var mouseDiffY:Number;
	
	private var _queryWindow:WiMInfoWindow;

	private var siteClicked:Boolean = false;
	
	private var nwisSiteX:Number;
	private var nwisSiteY:Number;

	[Bindable] 
	private var lastGridResult:String;
	
	public var infoBoxGraphic:Graphic;

	public var graphicIDArray:Array;
	
	[Bindable]
	public var gageValues:ArrayCollection = new ArrayCollection();
	[Bindable]
	public var gageValues2:ArrayCollection = new ArrayCollection();
	[Bindable]
	public var gageValues3:ArrayCollection = new ArrayCollection();
	[Bindable]
	public var altitudeValues:ArrayCollection = new ArrayCollection();
	[Bindable]
	public var altitudeValues2:ArrayCollection = new ArrayCollection();
	[Bindable]
	public var altitudeValues3:ArrayCollection = new ArrayCollection();
	[Bindable]
	public var dischargeValues:ArrayCollection = new ArrayCollection();
		
	public var gridInfos:ArrayCollection = new ArrayCollection();
	
	[Bindable]
	public var gridLayerIndex:Number;
	[Bindable]
	public var gridLayerIndexArrColl:ArrayCollection;
	
	[Bindable]
	public var sliderValue:Number = 0;
	[bindable]
	public var sliderValue_2:Number = 0;
	[Bindable]
	public var sliderValue_3:Number = 0;

	[Bindable]
	public var sliderGageValue:Number;
	[Bindable]
	public var sliderGageValue_2:Number;
	[Bindable]
	public var sliderGageValue_3:Number;


	[Bindable]
	public var gagePairs:ArrayCollection = new ArrayCollection();
	[Bindable]
	public var gagePairs2:ArrayCollection = new ArrayCollection();

	[Bindable]
	public var gageSet:ArrayCollection = new ArrayCollection();

	private var currentTimeStamp:String;

	[Bindable]
	public var coordsVals:ArrayCollection = new ArrayCollection(
		[ {label:"Geographic", data:"Lat: {0}, Lng: {1}"},
			{label:"USNG", data:"{mgrs}"} ]);
	
	[Bindable]
	private var mapLon:String = "";
	
	[Bindable]
	private var mapLat:String = "";
	
	[Bindable]
	private var mapNorth:String = "";
	
	[Bindable]
	private var mapEast:String = "";
	
	[Bindable]
	private var mgrs:String = "";
	
	private var m_geogToProg:CoordinateTransformation;

	[Bindable]
	public var hazus_cql:String = "";
	[Bindable]
	public var hazus_layers:String = "";
	[Bindable]
	public var hazus_sld:String = "";
	[Bindable]
	public var hazusWMSParams:ArrayCollection = new ArrayCollection();

	[Bindable]
	public var pretendAddBoxVis:Boolean = false;

	private var xmlResourceLoader:XmlResourceLoader = new XmlResourceLoader();

	[Bindable] private var majorCount:Number;
	[Bindable] private var moderateCount:Number;
	[Bindable] private var minorCount:Number;
	[Bindable] private var actionCount:Number;
	[Bindable] private var normalCount:Number;
	[Bindable] private var oldCount:Number;

	private var popUpBoxes:Object = new Object();

	private var ahpsIds:Array = new Array();

	public var snapToFlood:Function;

	public var initFloodSliderValue:Number;
	
	private var allGridInfos:Array;
	private var grid1Infos:Array;
	private var grid2Infos:Array;
	private var grid3Infos:Array;

	private var threeSiteGridInfos:Array;

	[Bindable]
	private var shortName:String;
	[Bindable]
	private var shortName2:String;
	[Bindable]
	private var shortName3:String;

	private var lods:Array;

	private var multiSitesQuery:Query = new Query();
	private var multiSitesQueryTask:QueryTask;	


	/*[Bindable]
	public var wmsImage:Image = new Image();*/


	private function setUp():void 
	{
		xmlResourceLoader.load(["locale/en_US", "en_US"]);
	}

	/**
	 * load mapper
	 * */

	private function mapLoad():void
	{   
		//code to adjust height of layer list and explanations for different screen sizes
		//use only if needed
		layerExpsMaxHeight = FlexGlobals.topLevelApplication.height - 390;
		
		ExternalInterface.addCallback("handleWheel", handleWheel);
		ExternalInterface.addCallback("rightClick", onRightClick);
		
		m_geogToProg = new CoordinateTransformation();
		m_geogToProg.init(ProjectedCS.WebMercator.geographicCS, ProjectedCS.WebMercator);
		map.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		
		map.addEventListener(KeyboardEvent.KEY_DOWN,keyPressed);
		
		initExtent = map.extent;
		
	}

	private function gridsLayerComp(event):void {
		var layer:String = event.layer.id;
		switch (layer) {
			/*case "fimi_grids":
				allGridInfos = fimi_grids.layerInfos;
				break;*/
			case "grids1":
				grid1Infos = grids1.layerInfos;
				break;
			case "grids2":
				grid2Infos = grids2.layerInfos;
				break;
			case "grids3":
				grid3Infos = grids3.layerInfos;
				break;
		}
	}

	private function basemapUpdate():void {
		if (siteLayer.graphicProvider.length == 0 && siteTask.url != null) {
			siteQuery.geometry = map.extent;
			var appVersion:String = resourceManager.getString('ui.text', 'subTitle');
			if (appVersion != null && appVersion == "") {
				siteQuery.where = "Public = 1";
			} else if (appVersion != null && (appVersion == "FOR DEVELOPMENT ONLY, NOT FOR PUBLIC DISTRIBUTION" || appVersion == "FOR REVIEW ONLY, NOT FOR PUBLIC DISTRIBUTION")) {
				siteQuery.where = "";
			}
			siteTask.execute(siteQuery,new AsyncResponder(siteResult, infoFault, {type: 'siteTask'}));
			
			var ahpsQueryCount:Query = new Query();
			ahpsQueryCount.where = "Status = 'normal' OR Status = 'no_flooding' OR Status = 'minor' OR Status = 'moderate' OR Status = 'major' OR Status = 'old' OR Status = 'action'";
			var ahpsQueryTask:QueryTask = new QueryTask();
			ahpsQueryTask.useAMF = false;
			ahpsQueryTask.disableClientCaching = true;
			ahpsQueryTask.url = resourceManager.getString('urls.nonWim', 'ahpsForecastUrl')+'/0';
			ahpsQueryTask.executeForCount(ahpsQueryCount, new AsyncResponder(ahpsCountResult, queryFault, {type: 'ahpsQueryTask'}));
			
			function ahpsCountResult(count:Number, token:Object = null):void {
				//trace(count);
				ahpsQueryCount.where = "Status = 'minor' OR Status = 'moderate' OR Status = 'major' OR Status = 'old' OR Status = 'action'";
				ahpsQueryCount.outFields = ['status'];
				ahpsQueryTask.execute(ahpsQueryCount, new AsyncResponder(ahpsResult, queryFault, {type: 'ahpsQueryTask'}));
				
				function ahpsResult(featureSet:FeatureSet, token:Object = null):void {
					trace(featureSet.features.length);
					normalCount = count-featureSet.features.length;
					var i:int;
					for (i=0; i < featureSet.features.length; i++) {
						if (featureSet.features[i].attributes.status == 'major') {
							if (isNaN(majorCount)) { majorCount = 0; }
							majorCount += 1;majorCount
						} else if (featureSet.features[i].attributes.status == 'moderate') {
							if (isNaN(moderateCount)) { moderateCount = 0; }
							moderateCount += 1;
						} else if (featureSet.features[i].attributes.status == 'minor') {
							if (isNaN(minorCount)) { minorCount = 0; }
							minorCount += 1;
						} else if (featureSet.features[i].attributes.status == 'action') {
							if (isNaN(actionCount)) { actionCount = 0; }
							actionCount += 1;
						} else if (featureSet.features[i].attributes.status == 'old') {
							if (isNaN(oldCount)) { oldCount = 0; }
							oldCount += 1;
						} 
					}
				}
			}
		}
	}

	private function keyPressed(evt:KeyboardEvent):void{
		if(evt.ctrlKey && evt.keyCode == 77 && pretendAddBoxVis == false) {
			pretendAddBoxVis = true;
		} else if (evt.ctrlKey && evt.keyCode == 77 && pretendAddBoxVis == true) {
			pretendAddBoxVis = false;
		}
	}

	protected function warningsTest_init(event:FlexEvent):void
	{
		warningsTest.layerDefinitions =
			[
				"pp_short = 'FF' OR pp_short = 'FL' OR pp_short = 'FA'"
			];
	}

	protected function ahpsForecastInit(event:FlexEvent):void
	{
		ahpsForecast.layerDefinitions = [];
	}

	private function onExtentChange(event:ExtentEvent):void
	{
		if (siteTask.url != null) {
			siteQuery.geometry = map.extent;
			siteTask.execute(siteQuery,new AsyncResponder(siteResult, infoFault, {type: 'siteTask'}));
		}
		
		var nwisSitesAlpha = map.level * 0.1;
		if (nwisSitesAlpha < 0.5) {
			nwisSitesAlpha = 0.5;
		} else if (nwisSitesAlpha > 1) {
			nwisSitesAlpha = 1;
		}
		
		//dev only
		//nwisSites.alpha = nwisSitesAlpha;
		//end dev only
		
		//testMap.extent = map.extent;
		//testMap.scale = map.scale;
	}
	
	//Handles click requests for map layer info
	private function onMapClick(event:MapMouseEvent):void
	{
		var infoGraphicsSymbol:InfoSymbol;
		var identifyParameters:IdentifyParameters = new IdentifyParameters();
		
		var nwisIdentifyParameters:IdentifyParameters = new IdentifyParameters();
		nwisSiteX = event.stageX;
		nwisSiteY = event.stageY;
		
		siteNo = StringUtil.trim(siteNo);
		
		if (queryGraphicsLayer.visible && queryGraphicsLayer.graphicProvider.length > 0 && gridInfos.length > 0) {
			
			infoGraphicsLayer.clear();
			
			var popup:Application = FlexGlobals.topLevelApplication as Application;
			
			infoGraphicsSymbol = gridSym;	    							    	
			
			//Create query object to for currently selected layer    			
			
			identifyParameters.returnGeometry = false;
			identifyParameters.layerOption = "all";
		
			for each (var floodGraphic:Graphic in  queryGraphicsLayer.graphicProvider)
			{	
				var graphicID:String = floodGraphic.id;
				var index:int = sliderValue;
				trace(index);
				var tempValue:Number = gageValues.getItemAt(index).gageValue;
				var id:String;
				if (multiSite == "0") {
					id = siteNo + tempValue.toFixed(2);
					if (graphicID.match(siteNo + tempValue.toFixed(2)) != null) {
						graphicIDArray = graphicID.split(siteNo + tempValue.toFixed(2));
						break;
					}
				} else if (multiSite == "1") {
					var index2:int = sliderValue_2;
					var tempValue2:Number = gageValues2.getItemAt(index2).gageValue;
					id = siteNo + tempValue.toFixed(2) + tempValue2.toFixed(2);
					if (graphicID.match(siteNo + tempValue.toFixed(2) + tempValue2.toFixed(2)) != null) {
						graphicIDArray = graphicID.split(siteNo + tempValue.toFixed(2) + tempValue2.toFixed(2));
						break;
					}
				} else if (multiSite == "2") {
					var index2:int = sliderValue_2;
					var tempValue2:Number = gageValues2.getItemAt(index2).gageValue;
					id = siteNo + tempValue.toFixed(2) + tempValue2.toFixed(2);
					trace(siteNo);
					if (graphicID.match(siteNo + tempValue.toFixed(2) + tempValue2.toFixed(2)) != null) {
						graphicIDArray = graphicID.split(siteNo + tempValue.toFixed(2) + tempValue2.toFixed(2));
					}
				} else if (multiSite == "3") {
					var index2:int = sliderValue_2;
					var index3:int = sliderValue_3;
					var tempValue2:Number = gageValues2.getItemAt(index2).gageValue;
					var tempValue3:Number = gageValues3.getItemAt(index3).gageValue;
					id = siteNo + tempValue.toFixed(2) + tempValue2.toFixed(2) + tempValue3.toFixed(2);
					if (graphicID.match(siteNo + tempValue.toFixed(2) + tempValue2.toFixed(2) + tempValue3.toFixed(2)) != null) {
						graphicIDArray = graphicID.split(siteNo + tempValue.toFixed(2) + tempValue2.toFixed(2) + tempValue3.toFixed(2));
						break;
					}
				} 
			}
				
			if (multiSite == "0" || multiSite == "1" || multiSite == "3") {
				identifyParameters.layerIds = [];
				gridLayerIndexArrColl = new ArrayCollection();
					
				for (var i:int; i < gridInfos.length; i++) {
					if (gridInfos[i].shortname == currentShortName && int(gridInfos[i].gridid) == int(graphicIDArray[1])) {
						identifyParameters.layerIds.push([gridInfos[i].index]);
						gridLayerIndexArrColl.addItem([gridInfos[i].index]);
						gridLayerIndex = gridInfos[i].index;
					} else if (gridInfos[i].shortname == currentShortName && gridInfos[i].gridid == graphicIDArray[1]+'b') {
						identifyParameters.layerIds.push([gridInfos[i].index]);
						gridLayerIndexArrColl.addItem([gridInfos[i].index]);
						gridLayerIndex = gridInfos[i].index;
					}
				}
				
				identifyParameters.width = map.width;
				identifyParameters.height = map.height;
				identifyParameters.geometry = event.mapPoint;
				identifyParameters.tolerance = 1;
				identifyParameters.mapExtent = map.extent;
				identifyParameters.spatialReference = map.spatialReference;										
				
				identifyTask.showBusyCursor = true;
				
				identifyTask.url = "http://gis.wim.usgs.gov/ArcGIS/rest/services/FIMTest/grids_" + grid_serv + "_test/MapServer";
				identifyTask.url = resourceManager.getString('urls', 'grids' + grid_serv);
				
	
				identifyTask.execute(identifyParameters, new AsyncResponder(gridResult, gridFault));
				
				//Create info box for results, but don't display it yet.
				infoBoxGraphic = new Graphic(event.mapPoint, infoGraphicsSymbol);
				infoBoxGraphic.name = "infoBoxGraphic";
				infoBoxGraphic.attributes = [];
				infoBoxGraphic.visible = false;
				
				//Add info box graphic to information layer
				infoGraphicsLayer.add(infoBoxGraphic); 	
				
			} else if (multiSite == "2") {
				
				infoGraphicsLayer.clear();
				
				infoGraphicsSymbol = gridSym;
				
				identifyParameters.returnGeometry = false;
				identifyParameters.layerOption = "visible";
				
				identifyParameters.layerIds = [];
				gridLayerIndexArrColl = new ArrayCollection();
				
				var sites:Array = [siteNo, siteNo_2, siteNo_3];
				
				var tempShortNames:Array = new Array();
				
				for (var k:int = 0; k < sites.length; k++) {
					for (var j:int = 0; j < siteLayer.graphicProvider.length; j++) {
						if (siteLayer.graphicProvider[j].attributes.SITE_NO.match(sites[k]) != null && k == 0) {
							shortName = siteLayer.graphicProvider[j].attributes.SHORT_NAME;
							if (tempShortNames.indexOf(siteLayer.graphicProvider[j].attributes.SHORT_NAME) == -1) {
								tempShortNames.push(siteLayer.graphicProvider[j].attributes.SHORT_NAME);
							}
						} else if (siteLayer.graphicProvider[j].attributes.SITE_NO.match(sites[k]) != null && k == 1) {
							shortName2 = siteLayer.graphicProvider[j].attributes.SHORT_NAME;
							if (tempShortNames.indexOf(siteLayer.graphicProvider[j].attributes.SHORT_NAME) == -1) {
								tempShortNames.push(siteLayer.graphicProvider[j].attributes.SHORT_NAME);
							}
						} else if (siteLayer.graphicProvider[j].attributes.SITE_NO.match(sites[k]) != null && k == 2) {
							shortName3 = siteLayer.graphicProvider[j].attributes.SHORT_NAME;
							if (tempShortNames.indexOf(siteLayer.graphicProvider[j].attributes.SHORT_NAME) == -1) {
								tempShortNames.push(siteLayer.graphicProvider[j].attributes.SHORT_NAME);
							}
						}
					}
				}
				
				for (var h:int = 0; h < tempShortNames.length; h++) {
					for (var i:int = 0; i < gridInfos.length; i++) {
						//trace(gridInfos[i].shortname);
						trace(tempShortNames[h]);
						if (gridInfos[i].shortname == tempShortNames[h] && int(gridInfos[i].gridid) == int(graphicIDArray[1])) {
							if (identifyParameters.layerIds.indexOf(gridInfos[i].index) == -1) {
								identifyParameters.layerIds.push(gridInfos[i].index);
							}
							gridLayerIndexArrColl.addItem(gridInfos[i].index);
							gridLayerIndex = gridInfos[i].index;
						} else if (gridInfos[i].shortname == tempShortNames[h] && gridInfos[i].gridid == graphicIDArray[1]+'b') {
							if (identifyParameters.layerIds.indexOf(gridInfos[i].index) == -1) {
								identifyParameters.layerIds.push(gridInfos[i].index);
							}
							gridLayerIndexArrColl.addItem(gridInfos[i].index);
							gridLayerIndex = gridInfos[i].index;
						}
					}
				}
				
				identifyParameters.width = map.width;
				identifyParameters.height = map.height;
				identifyParameters.geometry = event.mapPoint;
				identifyParameters.tolerance = 1;
				identifyParameters.mapExtent = map.extent;
				identifyParameters.spatialReference = map.spatialReference;										
				
				identifyTask.showBusyCursor = true;
				
				identifyTask.url = "http://gis.wim.usgs.gov/ArcGIS/rest/services/FIMTest/grids_" + grid_serv + "_test/MapServer";
				identifyTask.url = resourceManager.getString('urls', 'grids' + grid_serv);
				
				
				identifyTask.execute(identifyParameters, new AsyncResponder(gridResult, gridFault));
				
				//Create info box for results, but don't display it yet.
				infoBoxGraphic = new Graphic(event.mapPoint, infoGraphicsSymbol);
				infoBoxGraphic.name = "infoBoxGraphic";
				infoBoxGraphic.attributes = [];
				infoBoxGraphic.visible = false;
				
				//Add info box graphic to information layer
				infoGraphicsLayer.add(infoBoxGraphic); 	
				
			} 
		} 
		
		//Methods for identifying AHPS Forecast sites
		if (ahpsForecastMajorToggle.selected || ahpsForecastModerateToggle.selected || ahpsForecastMinorToggle.selected || ahpsForecastNormalToggle.selected || ahpsForecastActionToggle.selected || ahpsForecastOldToggle.selected) {
			
			//Create query object to for currently selected layer    			
			
			identifyParameters.returnGeometry = true;
			identifyParameters.layerIds = [0];
			identifyParameters.layerDefinitions = ahpsForecast.layerDefinitions;
			identifyParameters.width = map.width;
			identifyParameters.height = map.height;
			identifyParameters.geometry = event.mapPoint;
			identifyParameters.tolerance = 3;
			identifyParameters.mapExtent = map.extent;
			identifyParameters.spatialReference = map.spatialReference;										
			
			ahpsIdentifyTask.showBusyCursor = true;
			ahpsIdentifyTask.execute(identifyParameters, new AsyncResponder(ahpsIdentifyResult, ahpsIdentifyFault));
			
		}
		
		//dev only
		/*if (nwisSites.visible) {
			
			//Create query object to for currently selected layer    			
			
			nwisIdentifyParameters.returnGeometry = true;
			nwisIdentifyParameters.layerIds = [0,1];
			nwisIdentifyParameters.width = map.width;
			nwisIdentifyParameters.height = map.height;
			nwisIdentifyParameters.geometry = event.mapPoint;
			nwisIdentifyParameters.tolerance = 5;
			nwisIdentifyParameters.mapExtent = map.extent;
			nwisIdentifyParameters.spatialReference = map.spatialReference;										
			
			nwisIdentifyTask.showBusyCursor = true;
			nwisIdentifyTask.execute(nwisIdentifyParameters, new AsyncResponder(nwisIdentifyResult, nwisIdentifyFault));
			
		}*/
		//end dev only
		
	}

	private function roundToNearest(roundTo:Number, value:Number):Number{
		return Math.round(value/roundTo)*roundTo;
	}
	
	private function gridResult(results:Array, clickGraphic:Graphic = null):void
	{
		if (results && results.length > 0) {
			//this if only in place to deal with sites without a depth range even though it is a required field.
			if (depthRange == null) {
				depthRange = '1';
			}
			var factor:Number = (parseFloat(depthRange)/2) % 0.5;
			if (factor == 0) { //second half of OR only to handle libraries without depth range even though it is a required field
				factor = 0.5;
			}
			
			var finalGridID:String;
			var layerID:String;
			var gridID:String;
			var result:IdentifyResult;
			var resultGraphic:Graphic;
			
			// loop to determine which of the returned values is not "No Data" and handle breach visibility
			if (results.length > 1) {
				for (var i:int = 0; i < results.length; i++) {
					layerID = results[i].layerId.toString();
					gridID = getGridID(layerID);
					result = results[i];
					resultGraphic = result.feature;
					if (results[i].feature.attributes["Pixel Value"] != "NoData" && (gridID.match("b") != null && breachGraphicsLayer.visible == true)) {
						lastGridResult = resultGraphic.attributes["Pixel Value"];
						finalGridID = gridID;
					} else if (results[i].feature.attributes["Pixel Value"] != "NoData" && gridID.match("b") == null) {
						lastGridResult = resultGraphic.attributes["Pixel Value"];
						finalGridID = gridID;
					}
				}
			} else {
				layerID = results[i].layerId.toString();
				gridID = getGridID(layerID);
				result = results[i];
				resultGraphic = result.feature;
				if (result.feature.attributes["Pixel Value"] != "NoData" && (gridID.match("b") != null && breachGraphicsLayer.visible == true)) {
					lastGridResult = resultGraphic.attributes["Pixel Value"];
					finalGridID = gridID;
				} else {
					lastGridResult = resultGraphic.attributes["Pixel Value"];
					finalGridID = gridID;
				}
			}
			
			infoBoxGraphic.attributes.gridResult = lastGridResult;
			
			if (resultGraphic != null) {
				var gridAttr:Object = new ObjectProxy(resultGraphic.attributes);
				gridAttr.value = lastGridResult;
				var rndGridValue:Number = roundToNearest(factor,gridAttr.value);
				
				var lowValue:Number = rndGridValue-parseFloat(depthRange)/2;
				var highValue:Number = rndGridValue+parseFloat(depthRange)/2;
				
				//code to adjust value so range falls on .0s and .5s
				var roundingRemainder:Number = (rndGridValue+parseFloat(depthRange)/2) % 0.5;
				if (roundingRemainder != 0) {
					var diff:Number = rndGridValue - gridAttr.value;
					if (diff > 0) {
						lowValue = parseFloat((rndGridValue - parseFloat(depthRange)/2 - factor).toFixed(1));
						highValue = parseFloat((rndGridValue + parseFloat(depthRange)/2 - factor).toFixed(1));
					} else {
						lowValue = parseFloat((rndGridValue - parseFloat(depthRange)/2 + factor).toFixed(1));
						highValue = parseFloat((rndGridValue + parseFloat(depthRange)/2 + factor).toFixed(1));
					}
				}
				
				//check for negative values of lowValue
				if (lowValue < 0) {
					lowValue = 0;
				}
				
				//using depth range value in site file
				var range:String = lowValue.toString() + ' - ' + highValue.toString();
				//var range:String = (rndGridValue-0.5).toString() + ' - ' + (rndGridValue+0.5).toString();
				gridAttr.value = range;
				gridAttr.currentRepLink = currentRepLink;
				infoBoxGraphic.attributes = gridAttr;
				if (lastGridResult != 'NoData' && lastGridResult != '' && lastGridResult != null) {
					infoBoxGraphic.visible = true;
					infoGraphicsLayer.visible = true;
				}
				lastGridResult = '';
			}
		}
	}
	
	private function gridFault(error:Object, clickGraphic:Graphic = null):void
	{
		trace(error.toString());
	}

	private function getGridID(id:String):String {
		var gridID:String;
		
		var gridServ:Array;
		switch (grid_serv) {
			case "1":
				gridServ = grid1Infos;
				break;
			case "2":
				gridServ = grid2Infos;
				break;
			case "3":
				gridServ = grid3Infos;
				break;
			case null:
				gridServ = null;
				break;
		}
		
		gridID = gridServ[id].name.split("_")[1];
		
		return gridID;
	}
	
	private function ahpsIdentifyResult(results:Array, clickGraphic:Graphic = null):void
	{
		ahpsInfoLayer.clear();
		if (results && results.length > 0) {
			var result:com.esri.ags.tasks.supportClasses.IdentifyResult = results[0];         
			
			var infoGraphicsSymbol:InfoSymbol = ahpsForecastSym;
			
			//Create info box for results, but don't display it yet.
			infoBoxGraphic = new Graphic(result.feature.geometry, infoGraphicsSymbol);
			infoBoxGraphic.name = "infoBoxGraphic";
			infoBoxGraphic.attributes = result.feature.attributes;
			
			//Add info box graphic to information layer
			ahpsInfoLayer.add(infoBoxGraphic); 	
		}
	}

	private function ahpsIdentifyFault(error:Object, clickGraphic:Graphic = null):void
	{
		trace(error.toString());
	}

	private function nwisIdentifyResult(results:Array, clickGraphic:Graphic = null):void
	{	
		if (results && results.length > 0 && siteClicked == false) {
			
			var result:com.esri.ags.tasks.supportClasses.IdentifyResult = results[0];
			var allSites:ArrayCollection = siteLayer.graphicProvider as ArrayCollection;
			var inSites:Boolean = false;
			for (var i:int = 0; i < allSites.length; i++) {
				if (allSites[i].attributes.SITE_NO == result.feature.attributes.Name && inSites == false) {
					inSites = true
				}
			}
			
			if (inSites == false) {var vis:ArrayCollection = new ArrayCollection();
				vis.addItem(-1);
				//dev only
				/*gridsDyn.visibleLayers = vis;
				gridsDyn.refresh();
				
				gridsDynLegend.aLegendService.send();*/
				//end dev only
				
				floodExtentsDyn.layerDefinitions = ["OBJECTID = -1"];
				floodBreachDyn.layerDefinitions = ["OBJECTID = -1"];
				floodBreachMultiDyn.layerDefinitions = ["OBJECTID = -1"];
				floodMultiSitesDyn.layerDefinitions = ["OBJECTID = -1"];
				floodMultiSitesDyn2.layerDefinitions = ["OBJECTID = -1"];
				supplementalLayers.layerDefinitions = ["OBJECTID = -1", "OBJECTID = -1"];
				
				infoGraphicsLayer.clear();
				queryGraphicsLayer.clear();
				breachGraphicsLayer.clear();
				PopUpManager.removePopUp(_queryWindow);
				
				siteNo = result.feature.attributes.Name;
				if (result.feature.attributes.CH5ID == "Null") {
					ahpsID = "None";
				} else {
					ahpsID = result.feature.attributes.CH5ID;
				}
				
				
				_queryWindow = PopUpManager.createPopUp(map, nwisWindow, false) as WiMInfoWindow;
				_queryWindow.setStyle("skinClass", WiMInfoWindowSkin);
				
				if (isNaN(nwisSiteX) || isNaN(nwisSiteY)) {
					_queryWindow.x = FlexGlobals.topLevelApplication.width/2+10;
					_queryWindow.y = FlexGlobals.topLevelApplication.height/2-10;
				} else {
					_queryWindow.x = nwisSiteX;
					_queryWindow.y = nwisSiteY;
				}
				
				_queryWindow.addEventListener(CloseEvent.CLOSE, closePopUp);
				_queryWindow.data = result.feature.attributes;
				//siteInfoBox.visible = true;
				
				var aGraphic:Graphic = result.feature;
				
				aGraphic.symbol = nwisSiteSelectedSym;
				queryGraphicsLayer.add(aGraphic);
				
				queryGraphicsLayer.visible = true;
				queryGraphicsLayer.alpha = 1.0;
			}
		} else {
			siteClicked = false;
		}
	}
	
	private function nwisIdentifyFault(error:Object, clickGraphic:Graphic = null):void
	{
		trace('nwisIdentify error: ' + error.toString());
	}
	
	private function floodBoxClose():void 
	{
		queryGraphicsLayer.visible = false;
		map.infoWindow.hide();
	}
	
	
	/* function for feedback of lat/lng of current mouse position */
	private function mouseMove(event:MouseEvent):void
	{
		if (map.loaded) {
			var mapPoint:MapPoint = map.toMapFromStage(event.stageX, event.stageY);
			var mapPt:MapPoint = WebMercatorUtil.webMercatorToGeographic(mapPoint) as MapPoint;
			mapX = mapPt.x;
			mapY = mapPt.y;
			mapNorth = mapPoint.y.toFixed(0);
			mapEast = mapPoint.x.toFixed(0);
			var pt:Point = new Point(mapPoint.x, mapPoint.y);
			m_geogToProg.projectInverse(pt);
			mgrs = MoreUtils.getMGRSString(pt.y, pt.x);
			mapLon = Utilities.radiansToDMSString(pt.x*Math.PI/180);
			mapLat = Utilities.radiansToDMSString(pt.y*Math.PI/180);
			
			dispatchEvent(new Event("coordsLabelChange"));
		}
	}
	
	/* Query tooltip methods */
	
	
	
	private function infoSingleResult(resultSet:Array, configObjects:ArrayCollection):void
	{
		
		if (resultSet.length != 0) {
			
			var aGraphic:Graphic = resultSet[0].feature;
			
			if (aGraphic.attributes[configObjects[0]] != 0) {
				
				aGraphic.symbol = aQuerySym;
				//queryGraphicsLayer.add(aGraphic);
				
				var infoBoxGraphic:Graphic = infoGraphicsLayer.getChildByName("infoBoxGraphic") as Graphic;
				
				infoBoxGraphic.attributes = new ObjectProxy(aGraphic.attributes);
				infoBoxGraphic.attributes["title"] = configObjects[1];
				infoBoxGraphic.attributes["value"] = aGraphic.attributes[configObjects[0]];
				infoBoxGraphic.visible = true;
				infoGraphicsLayer.refresh();		            
			} 	            	
		} 
	}  
	
	private function infoFault(info:Object, token:Object = null):void
	{
		//Alert.show(info.toString());
		trace(token.type + ":" + info.toString());
	} 
	
	private function siteResult(featureSet:FeatureSet, token:Object = null):void
	{
		var sites:FeatureSet = featureSet;
		
		for each (var site:Graphic in featureSet.features) {
			var siteAHPS:String = site.attributes.AHPS_ID;
			if (siteAHPS != '' && siteAHPS != 'NONE' && siteAHPS != null) {
				ahpsIds.push("'" + siteAHPS.toUpperCase() + "'");
			}
		}
		
		var ahpsFloodQuery:Query = new Query();
		ahpsFloodQuery.where = "GaugeLID in (" + ahpsIds.toString() + ")";
		ahpsFloodQuery.returnGeometry = false;
		ahpsFloodQuery.geometry = map.extent;
		ahpsFloodQuery.outFields = ['status','gaugelid'];
		var ahpsFloodTask:QueryTask = new QueryTask();
		ahpsFloodTask.useAMF = false;
		ahpsFloodTask.disableClientCaching = true;
		ahpsFloodTask.url = resourceManager.getString('urls.nonWim', 'ahpsForecastUrl') + '/0';
		ahpsFloodTask.execute(ahpsFloodQuery, new AsyncResponder(ahpsFloodResult, queryFault, {type: 'ahpsFloodTask', where: ahpsFloodQuery.where}));
		
		function ahpsFloodResult(featureSet:FeatureSet, token:Object = null):void {
			var floodAttr:Object = featureSet.attributes;
			
			var i:int;
			
			for (i = 0; i < floodAttr.length; i++) {
				var testVariable:String;
				//trace('stage: ' + floodAttr[i].stage);
				for (var j:int = 0; j < sites.features.length; j++) {
					if (siteLayer.graphicProvider[j].attributes.AHPS_ID == floodAttr[i].gaugelid.toLowerCase()) {
						siteLayer.graphicProvider[j].attributes["floodCondition"] = floodAttr[i].status;
						var nothing:String = 'something';
					}
				}
			}
			
			siteLayer.refresh();
		}
		
		for each (var siteGraphic:Graphic in featureSet.features)
		{
			var graphicID:String = siteGraphic.attributes.SITE_NO;
			var siteSt:String = siteGraphic.attributes.STATE;
			var siteComm:String = siteGraphic.attributes.COMMUNITY;
			
			if (!siteExisting[graphicID])
			{
				siteExisting[graphicID] = 1;
				
				siteGraphic.id = graphicID;
				
				siteGraphic.toolTip = siteSt + ": " + siteComm;
				
				siteGraphic.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void {
					
					siteClicked = true;
					
					var tempAC = new ArrayCollection();
					
					gridsReset(true, -1, tempAC);
					
					floodExtentsDyn.layerDefinitions = ["OBJECTID = -1"];
					floodBreachDyn.layerDefinitions = ["OBJECTID = -1"];
					floodBreachMultiDyn.layerDefinitions = ["OBJECTID = -1"];
					floodMultiSitesDyn.layerDefinitions = ["OBJECTID = -1"];
					floodMultiSitesDyn2.layerDefinitions = ["OBJECTID = -1"];
					supplementalLayers.layerDefinitions = ["OBJECTID = -1", "OBJECTID = -1"];
					
					var siteAttributes:Object = event.currentTarget.attributes;
					
					gageValues = new ArrayCollection();
					gageValues2 = new ArrayCollection();
					gageValues3 = new ArrayCollection();
					altitudeValues = new ArrayCollection();
					altitudeValues2 = new ArrayCollection();
					altitudeValues3 = new ArrayCollection();
					dischargeValues = new ArrayCollection();
					gridInfos = new ArrayCollection();
					
					if (map.level < 12) {
						map.centerAt(event.currentTarget.geometry as MapPoint);
						map.level = 13;
					}
					
					//var siteGraphic:Graphic = event.target;
					infoGraphicsLayer.clear();
					queryGraphicsLayer.clear();
					breachGraphicsLayer.clear();
					PopUpManager.removePopUp(_queryWindow);
					
					var currentSiteNo:String = event.currentTarget.attributes.SITE_NO;
					ahpsID = event.currentTarget.attributes.AHPS_ID;
					multiSite = event.currentTarget.attributes.MULTI_SITE;
					currentRepLink = event.currentTarget.attributes.REP_LINK;
					currentReport = event.currentTarget.attributes.REPORT;
					depthRange = event.currentTarget.attributes.DEPTH_RANG;
					//depthRange = '1';
					siteFID = event.currentTarget.attributes.OBJECTID;
					siteState = event.currentTarget.attributes.STATE;
					siteCommunity = event.currentTarget.attributes.COMMUNITY;
					authors = event.currentTarget.attributes.AUTHORS;
					rep_date = event.currentTarget.attributes.REP_DATE;
					study_date = event.currentTarget.attributes.STUDY_DATE;
					title = event.currentTarget.attributes.TITLE;
					rep_series = event.currentTarget.attributes.REP_SERIES;
					series_num = event.currentTarget.attributes.SERIES_NUM;
					add_info = event.currentTarget.attributes.ADD_INFO;
					grid_serv = event.currentTarget.attributes.GRID_SERV;
					
					var mapPoint:MapPoint;
					if (isNaN(event.stageX) || isNaN(event.stageY)) {
						mapPoint = map.toMapFromStage(FlexGlobals.topLevelApplication.width/2+10,FlexGlobals.topLevelApplication.height/2-10);
					} else {
						mapPoint = map.toMapFromStage(event.stageX, event.stageY);
					}
					var mapPt:MapPoint = WebMercatorUtil.webMercatorToGeographic(mapPoint) as MapPoint;
					siteX = mapPt.x;
					siteY = mapPt.y;
					
					/*
					//Generate timestamp to set a currentTimeStamp variable? Also update multisite code.
					*/
					
					var now:Date = new Date();
					currentTimeStamp = now.toString();
					
					if (multiSite == '0') {
						siteNo = event.currentTarget.attributes.SITE_NO;
						currentShortName = event.currentTarget.attributes.SHORT_NAME;
						/*if (siteAttributes.HAS_HAZUS == 1 && siteAttributes.HAS_WEBCAM == 1) {
							_queryWindow = PopUpManager.createPopUp(map, FloodToolsWindow, false) as WiMInfoWindow;
						} else if (siteAttributes.HAS_HAZUS == 1) {
							_queryWindow = PopUpManager.createPopUp(map, FloodToolsWindowHazus, false) as WiMInfoWindow;
						} else if (siteAttributes.HAS_WEBCAM == 1) {
							_queryWindow = PopUpManager.createPopUp(map, FloodToolsWindowWebcam, false) as WiMInfoWindow;
						} else {
							_queryWindow = PopUpManager.createPopUp(map, FloodToolsWindowSmall, false) as WiMInfoWindow;
						}*/
						
						_queryWindow = PopUpManager.createPopUp(map, FloodToolsWindow, false) as WiMInfoWindow;
						_queryWindow.setStyle("skinClass", WiMInfoWindowSkin);
						
						if (isNaN(event.stageX) || isNaN(event.stageY)) {
							_queryWindow.x = FlexGlobals.topLevelApplication.width/2+10;
							_queryWindow.y = FlexGlobals.topLevelApplication.height/2-10;
						} else {
							_queryWindow.x = event.stageX;
							_queryWindow.y = event.stageY;
						}
						
						_queryWindow.addEventListener(CloseEvent.CLOSE, closePopUp);
						_queryWindow.data = event.currentTarget.attributes;
						//siteInfoBox.visible = true;
						
						queryGraphicsLayer.visible = true;
						
						floodQuery.geometry = map.extent;
						floodQuery.where = "USGSID = '" + currentSiteNo + "'"; // add this on for testing harrisburg AND STAGE < 20;
						
						libraryEnvQuery.geometry = map.extent;
						libraryEnvQuery.where = "USGSID = '" + currentSiteNo + "'"
						
						floodTask.execute(floodQuery, new AsyncResponder(floodResult, infoFault, {jobTime: currentTimeStamp, type: 'floodTask'}));
						//floodTask.execute(libraryEnvQuery, new AsyncResponder(libEnvResult, infoFault, {jobTime: currentTimeStamp, type: 'libEnvQuery'}));
						
						if (event.currentTarget.attributes.HAS_BREACH == 1) {
							
						}
					} else if (multiSite == '1') {
						currentShortName = event.currentTarget.attributes.SHORT_NAME;
						multiSitesQuery.returnGeometry = false;
						if (currentSiteNo.length == 7) { 
							currentSiteNo = '0' + currentSiteNo;
						}
						multiSitesQuery.where = "site_no =" + currentSiteNo;
						multiSitesQuery.outFields = ["combo_id"];
						
						multiSitesQueryTask = new QueryTask(resourceManager.getString('urls', 'floodExtentsMultiTableUrl'));	
						multiSitesQueryTask.useAMF = false;
						multiSitesQueryTask.disableClientCaching = true;
						multiSitesQueryTask.showBusyCursor = true;
						multiSitesQueryTask.execute(multiSitesQuery, new AsyncResponder(multiSitesResult, queryFault, {type: 'multiSitesQueryTask'}));
						
						function multiSitesResult(featureSet:FeatureSet, token:Object = null):void
						{	
							var extentsQuery:Query = new Query();
							extentsQuery.returnGeometry = false;
							extentsQuery.where = "combo_id =" + featureSet.features[0].attributes.combo_id;
							extentsQuery.outFields = ["site_no,combo_id,ordinal"];
							
							var extentsQueryTask:QueryTask = new QueryTask(resourceManager.getString('urls', 'floodExtentsMultiTableUrl'));	
							extentsQueryTask.useAMF = false;
							extentsQueryTask.disableClientCaching = true;
							extentsQueryTask.showBusyCursor = true;
							extentsQueryTask.execute(extentsQuery, new AsyncResponder(extentsInitResult, queryFault, {type: 'extentsQueryTask'}));
							
							function extentsInitResult(featureSet:FeatureSet, token:Object = null):void
							{
								var i:int;
								for (i=0;i<featureSet.features.length;i++) {
									if (featureSet.features[i].attributes.ordinal == 1) {
										siteNo = featureSet.features[i].attributes.site_no;
									} else if (featureSet.features[i].attributes.ordinal == 2) {
										siteNo_2 = featureSet.features[i].attributes.site_no;
									}
								}
								if (featureSet.features.length > 1) {
									if (featureSet.features[0].attributes.ordinal == 1) {
										if (featureSet.features[0].attributes.site_no.toString().length == 7) { 
											siteNo = '0' + featureSet.features[0].attributes.site_no;
										} else {
											siteNo = featureSet.features[0].attributes.site_no;
										}
										
										_queryWindow = PopUpManager.createPopUp(map, FloodToolsWindowMultiSites, false) as WiMInfoWindow;
										_queryWindow.setStyle("skinClass", WiMInfoWindowSkin);
										if (isNaN(event.stageX) || isNaN(event.stageY)) {
											_queryWindow.x = FlexGlobals.topLevelApplication.width/2+10;
											_queryWindow.y = FlexGlobals.topLevelApplication.height/2-10;
										} else {
											_queryWindow.x = event.stageX;
											_queryWindow.y = event.stageY;
										}
										_queryWindow.addEventListener(CloseEvent.CLOSE, closePopUp);
										//siteInfoBox.visible = true;
										
										queryGraphicsLayer.visible = true;
										floodMultiQuery.geometry = map.extent;
										floodMultiQuery.where = "USGSID_1 = '0" + featureSet.features[0].attributes.site_no + "'";
										floodMultiTask.execute(floodMultiQuery,new AsyncResponder(floodMultiResult, infoFault, {jobTime: currentTimeStamp, type: 'floodMultiTask'}));
										
										libraryEnvQuery.geometry = map.extent;
										libraryEnvQuery.where = "USGSID_1 = '0" + featureSet.features[0].attributes.site_no + "'";
										
										//floodMultiTask.execute(libraryEnvQuery, new AsyncResponder(libEnvResult, infoFault, {jobTime: currentTimeStamp, type: 'libEnvQuery'}));
										
									} else if (featureSet.features[0].attributes.ordinal == 2) {
										if (featureSet.features[0].attributes.site_no.toString().length == 7) { 
											siteNo_2 = '0' + featureSet.features[0].attributes.site_no;
										} else {
											siteNo_2 = featureSet.features[0].attributes.site_no;
										}
										
										_queryWindow = PopUpManager.createPopUp(map, FloodToolsWindowMultiSites, false) as WiMInfoWindow;
										_queryWindow.setStyle("skinClass", WiMInfoWindowSkin);
										if (isNaN(event.stageX) || isNaN(event.stageY)) {
											_queryWindow.x = FlexGlobals.topLevelApplication.width/2+10;
											_queryWindow.y = FlexGlobals.topLevelApplication.height/2-10;
										} else {
											_queryWindow.x = event.stageX;
									   		_queryWindow.y = event.stageY;
										}
										_queryWindow.addEventListener(CloseEvent.CLOSE, closePopUp);
										//siteInfoBox.visible = true;
										
										queryGraphicsLayer.visible = true;
										floodMultiQuery.geometry = map.extent;
										floodMultiQuery.where = "USGSID_2 = '0" + featureSet.features[0].attributes.site_no + "'";
										floodMultiTask.execute(floodMultiQuery,new AsyncResponder(floodMultiResult, infoFault, {jobTime: currentTimeStamp, type: 'floodMultiTask'}));
										
										libraryEnvQuery.geometry = map.extent;
										libraryEnvQuery.where = "USGSID_2 = '0" + featureSet.features[0].attributes.site_no + "'";
										
										//floodMultiTask.execute(libraryEnvQuery, new AsyncResponder(libEnvResult, infoFault, {jobTime: currentTimeStamp, type: 'libEnvQuery'}));
									}
								}
							}
							
						}
					} else if (multiSite == '2') { // start with this code for multiSite == 3
						
						if (allGridInfos != null) {
							threeSiteGridInfos = allGridInfos;
						}
						
						currentShortName = event.currentTarget.attributes.SHORT_NAME;
						multiSitesQuery.returnGeometry = false;
						if (currentSiteNo.length == 7) { 
							currentSiteNo = '0' + currentSiteNo;
						}
						multiSitesQuery.where = "site_no =" + currentSiteNo;
						multiSitesQuery.outFields = ["combo_id"];
						
						multiSitesQueryTask = new QueryTask(resourceManager.getString('urls', 'floodExtentsMultiTableUrl'));	
						multiSitesQueryTask.useAMF = false;
						multiSitesQueryTask.disableClientCaching = true;
						multiSitesQueryTask.showBusyCursor = true;
						multiSitesQueryTask.execute(multiSitesQuery, new AsyncResponder(multiSitesResult_test, queryFault, {type: 'multiSitesQueryTask'}));
						
						function multiSitesResult_test(featureSet:FeatureSet, token:Object = null):void
						{	
							var extentsQuery:Query = new Query();
							extentsQuery.returnGeometry = false;
							extentsQuery.where = "combo_id =" + featureSet.features[0].attributes.combo_id;
							extentsQuery.outFields = ["site_no,combo_id,ordinal"];
							
							var extentsQueryTask:QueryTask = new QueryTask(resourceManager.getString('urls', 'floodExtentsMultiTableUrl'));	
							extentsQueryTask.useAMF = false;
							extentsQueryTask.disableClientCaching = true;
							extentsQueryTask.showBusyCursor = true;
							extentsQueryTask.execute(extentsQuery, new AsyncResponder(extentsInitResult, queryFault, {type: 'extentsQueryTask'}));
							
							function extentsInitResult(featureSet:FeatureSet, token:Object = null):void
							{
								if (featureSet.features.length > 1) {
									for (var i:int=0;i<featureSet.features.length;i++) {
										if (featureSet.features[i].attributes.ordinal == 1) {
											siteNo = fixSiteNo(featureSet.features[i].attributes.site_no);
										} else if (featureSet.features[i].attributes.ordinal == 2) {
											siteNo_2 = fixSiteNo(featureSet.features[i].attributes.site_no);
										} else if (featureSet.features[i].attributes.ordinal == 3) {
											siteNo_3 = fixSiteNo(featureSet.features[i].attributes.site_no);
										}
									}
									
									function fixSiteNo(inputNo:String):String {
										var siteNo:String = '';
										
										if (inputNo.length == 7) { 
											siteNo = '0' + inputNo;
										} else {
											siteNo = inputNo;
										}
										
										return siteNo;
									}
									
									if (featureSet.features.length > 1) {
										//loop through each site and do the query then open popup after all requests are made, use config object to get 
										for each (var feature:Graphic in featureSet.features) {
											if (feature.attributes.ordinal == 1 || feature.attributes.ordinal == 2) {
												floodMultiThreeSiteQuery.geometry = map.extent;
												floodMultiThreeSiteQuery.returnGeometry = false;
												floodMultiThreeSiteQuery.where = "USGSID_1 LIKE '%" + feature.attributes.site_no + "%'";
												floodMultiThreeSiteTask.execute(floodMultiThreeSiteQuery,new AsyncResponder(floodMultiThreeSiteResult, infoFault, {jobTime: currentTimeStamp, type: 'floodMultiThreeSiteTask', ordinal: feature.attributes.ordinal}));
											
												libraryEnvQuery.geometry = map.extent;
												libraryEnvQuery.where = "USGSID_1 LIKE '%" + feature.attributes.site_no + "%'";
												
												//floodMultiThreeSiteTask.execute(libraryEnvQuery, new AsyncResponder(libEnvResult, infoFault, {jobTime: currentTimeStamp, type: 'libEnvQuery'}));
											}
										}
										_queryWindow = PopUpManager.createPopUp(map, FloodToolsWindowMultiSites_test, false) as WiMInfoWindow;
										_queryWindow.setStyle("skinClass", WiMInfoWindowSkin);
										if (isNaN(event.stageX) || isNaN(event.stageY)) {
											_queryWindow.x = FlexGlobals.topLevelApplication.width/2+10;
											_queryWindow.y = FlexGlobals.topLevelApplication.height/2-10;
										} else {
											_queryWindow.x = event.stageX;
											_queryWindow.y = event.stageY;
										}
										_queryWindow.addEventListener(CloseEvent.CLOSE, closePopUp);
									}
								}
							}
							
						}
					} else if (multiSite == '3') { // start with this code for multiSite == 3
						
						if (allGridInfos != null) {
							threeSiteGridInfos = allGridInfos;
						}
						
						currentShortName = event.currentTarget.attributes.SHORT_NAME;
						multiSitesQuery.returnGeometry = false;
						if (currentSiteNo.length == 7) { 
							currentSiteNo = '0' + currentSiteNo;
						}
						multiSitesQuery.where = "site_no =" + currentSiteNo;
						multiSitesQuery.outFields = ["combo_id"];
						
						var url:String = resourceManager.getString('urls', 'floodExtentsThreeTableUrl');
						
						multiSitesQueryTask = new QueryTask(resourceManager.getString('urls', 'floodExtentsThreeTableUrl'));	
						multiSitesQueryTask.useAMF = false;
						multiSitesQueryTask.disableClientCaching = true;
						multiSitesQueryTask.showBusyCursor = true;
						multiSitesQueryTask.execute(multiSitesQuery, new AsyncResponder(threeSitesResult_test, queryFault, {type: 'multiSitesQueryTask'}));
						
						function threeSitesResult_test(featureSet:FeatureSet, token:Object = null):void
						{	
							var extentsQuery:Query = new Query();
							extentsQuery.returnGeometry = false;
							extentsQuery.where = "combo_id =" + featureSet.features[0].attributes.combo_id;
							extentsQuery.outFields = ["site_no,combo_id,ordinal"];
							
							var extentsQueryTask:QueryTask = new QueryTask(resourceManager.getString('urls', 'floodExtentsThreeTableUrl'));	
							extentsQueryTask.useAMF = false;
							extentsQueryTask.disableClientCaching = true;
							extentsQueryTask.showBusyCursor = true;
							extentsQueryTask.execute(extentsQuery, new AsyncResponder(extentsInitResult, queryFault, {type: 'extentsQueryTask'}));
							
							function extentsInitResult(featureSet:FeatureSet, token:Object = null):void
							{
								if (featureSet.features.length > 1) {
									for (var i:int=0;i<featureSet.features.length;i++) {
										if (featureSet.features[i].attributes.ordinal == 1) {
											siteNo = fixSiteNo(featureSet.features[i].attributes.site_no);
										} else if (featureSet.features[i].attributes.ordinal == 2) {
											siteNo_2 = fixSiteNo(featureSet.features[i].attributes.site_no);
										} else if (featureSet.features[i].attributes.ordinal == 3) {
											siteNo_3 = fixSiteNo(featureSet.features[i].attributes.site_no);
										}
									}
									
									function fixSiteNo(inputNo:String):String {
										var siteNo:String = '';
										
										if (inputNo.length == 7) { 
											siteNo = '0' + inputNo;
										} else {
											siteNo = inputNo;
										}
										
										return siteNo;
									}
									
									if (featureSet.features.length > 1) {
										//loop through each site and do the query then open popup after all requests are made, use config object to get 
										for each (var feature:Graphic in featureSet.features) {
											if (feature.attributes.ordinal == 1) {
												floodMultiAllThreeSiteQuery.geometry = map.extent;
												floodMultiAllThreeSiteQuery.returnGeometry = false;
												floodMultiAllThreeSiteQuery.where = "USGSID_1 LIKE '%" + feature.attributes.site_no + "%'";
												floodMultiAllThreeSiteTask.execute(floodMultiAllThreeSiteQuery,new AsyncResponder(floodMultiAllThreeSiteResult, infoFault, {jobTime: currentTimeStamp, type: 'floodThreeSiteTask', ordinal: feature.attributes.ordinal}));
												
												libraryEnvQuery.geometry = map.extent;
												libraryEnvQuery.where = "USGSID_1 LIKE '%" + feature.attributes.site_no + "%'";
											
												//floodMultiThreeSiteTask.execute(libraryEnvQuery, new AsyncResponder(libEnvResult, infoFault, {jobTime: currentTimeStamp, type: 'libEnvQuery'}));
											}
										}
										_queryWindow = PopUpManager.createPopUp(map, FloodToolsWindowThreeSites, false) as WiMInfoWindow;
										_queryWindow.setStyle("skinClass", WiMInfoWindowSkin);
										if (isNaN(event.stageX) || isNaN(event.stageY)) {
											_queryWindow.x = FlexGlobals.topLevelApplication.width/2+10;
											_queryWindow.y = FlexGlobals.topLevelApplication.height/2-10;
										} else {
											_queryWindow.x = event.stageX;
											_queryWindow.y = event.stageY;
										}
										_queryWindow.addEventListener(CloseEvent.CLOSE, closePopUp);
									}
								}
							}
							
						}
					}
				});
				siteGraphic.addEventListener(MouseEvent.MOUSE_OVER, animateOver);
				siteLayer.add(siteGraphic);
				
				var params:Object = getURLParameters();
				if (params["siteno"]) {
					if (siteGraphic.id == params["siteno"]) {
						map.centerAt(siteGraphic.geometry as MapPoint);
						map.level = 13;
						//This is a start. Need to have popup open near middle of browser and 
						//handle for popup opening before disclaimer clicked
						//also create click at the location of the site graphic as with normal click...
						//maybe attach click event to OKing of disclaimer
						siteGraphic.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
					}
				} 
			}
		}
				
		//put code here for ahps flood condition		
				
	}
				
	public function closePopUp(event:CloseEvent):void {
		PopUpManager.removePopUp(event.currentTarget as WiMInfoWindow);
		queryGraphicsLayer.clear();
		breachGraphicsLayer.clear();
		hazusWMS.visible = false;
		hazus_cql = "";
		hazus_layers = "";
		hazus_sld = "";
		hazusWMSParams = new ArrayCollection();
		
		var tempAC = new ArrayCollection();
		
		gridsReset(true, -1, tempAC);
		
		floodExtentsDyn.layerDefinitions = ["OBJECTID = -1"];
		floodBreachDyn.layerDefinitions = ["OBJECTID = -1"];
		floodBreachMultiDyn.layerDefinitions = ["OBJECTID = -1"];
		floodMultiSitesDyn.layerDefinitions = ["OBJECTID = -1"];
		floodMultiSitesDyn2.layerDefinitions = ["OBJECTID = -1"];
		floodThreeSitesDyn.layerDefinitions = ["OBJECTID = -1"];
		supplementalLayers.layerDefinitions = ["OBJECTID = -1", "OBJECTID = -1"];
		
		supplementalLayers.visible = false;
		floodExtentLegend.visible = false;
		
		breachLegend.visible = false;
	}
	
	public function gridsReset(hideLegend:Boolean,layerIndex:Number,layerIndexArray:ArrayCollection):void {
		//dev only
		/*var vis:ArrayCollection = new ArrayCollection();
		vis.addItem(layerIndex);
		
		//gridsDyn.url = "http://gis.wim.usgs.gov/ArcGIS/rest/services/FIMTest/grids_" + grid_serv + "_test/MapServer";
		gridsDyn.url = resourceManager.getString('urls', 'grids' + grid_serv);
		gridsDyn.visibleLayers = layerIndexArray;
		gridsDyn.refresh();
		
		if (grid_serv != null) {
			//var gridLayer:ArcGISDynamicMapServiceLayer = map.getLayer('grids' + grid_serv) as ArcGISDynamicMapServiceLayer;
			//gridLayer.visibleLayers = layerIndexArray;
			//gridsDynLegend.serviceLayer = gridLayer;
			var url:String = resourceManager.getString('urls', 'grids' + grid_serv);
			gridsDynLegend.aLegendService.url = url + "/legend?f=json";
			gridsDynLegend.aLegendService.send();
		}
			
		//grids1.visibleLayers = layerIndexArray;
		//grids1.refresh();
		
		//var gridLayer:ArcGISDynamicMapServiceLayer = map.getLayer('grids' + grid_serv) as ArcGISDynamicMapServiceLayer;
		//gridsDynLegend.serviceLayer = gridLayer;
		//grids1Legend.aLegendService.send();
		
		if (hideLegend == true) {
			gridsDynLegend.visible = false;
		} else if (hideLegend == false) {
			gridsDynLegend.visible = true;
		}*/
		
		/*if (hideLegend == true) {
			grids1Legend.visible = false;
		} else if (hideLegend == false) {
			grids1Legend.visible = true;
		}*/
		//end dev only
	}
				
	private function queryFault(info:Object, token:Object = null):void
	{
		trace(token.type + ": " + info.toString() + '\n' + token.where);
	} 
	
	private function getURLParameters():Object
	{
		var result:URLVariables = new URLVariables();
		
		try
		{
			if (ExternalInterface.available)
			{
				// Use JavaScript to get the search string from the current browser location.
				// Use substring() to remove leading '?'.
				// See http://livedocs.adobe.com/flex/3/langref/flash/external/ExternalInterface.html
				var search:String = ExternalInterface.call("location.search.substring", 1);
				if (search && search.length > 0)
				{
					result.decode(search);
				}
			}
		}
		catch (error:Error)
		{
			Alert.show(error.toString());
		}
		
		return result;
	}
	
	private function libEnvResult(featureSet:FeatureSet, token:Object = null):void {
		queryGraphicsLayer.add(featureSet.features[0]);
		queryGraphicsLayer.alpha = 0;
	}
	
	private function floodResult(featureSet:FeatureSet, token:Object = null):void
	{
		floodExisting = new Object();
		getGridInfo();
		gridLayerIndex = -1;
		gridLayerIndexArrColl = new ArrayCollection();
		
		if (currentTimeStamp != token.jobTime) { return };
		
		libraryEnvQuery.geometry = map.extent;
		libraryEnvQuery.where =  "(USGSID LIKE '%" + featureSet.features[0].attributes.USGSID + "%' AND STAGE = " + featureSet.features[0].attributes.STAGE + ")";
		
		floodTask.execute(libraryEnvQuery, new AsyncResponder(libEnvResult, infoFault, {type: 'libEnvQuerySingle'}));
		
		for each (var floodGraphic:Graphic in featureSet.features)
		{	
			var graphicID:String = floodGraphic.attributes.USGSID + floodGraphic.attributes.STAGE.toFixed(2) + floodGraphic.attributes.GRIDID;
			gageValues.addItem({gageValue:floodGraphic.attributes.STAGE.toFixed(2)});
			altitudeValues.addItem({altitudeValue:floodGraphic.attributes.ELEV.toFixed(2)});
			if (floodGraphic.attributes.QCFS != null) {
				dischargeValues.addItem({dischargeValue:floodGraphic.attributes.QCFS.toFixed(2)});
			} else {
				dischargeValues.addItem({dischargeValue:null});
			}
			if (!floodExisting[graphicID])
			{
				floodExisting[graphicID] = 1;
				floodGraphic.symbol = aQuerySym;
				
				if (graphicID.match(siteNo + gageValues.getItemAt(0).gageValue) != null) {
					floodGraphic.visible = true;
				} else {
					floodGraphic.visible = false;
				}
				
				floodGraphic.id = graphicID;
				if(gridInfos.length > 0) {
					floodGraphic.toolTip = "Click for estimated water depth";
				}
				queryGraphicsLayer.add(floodGraphic);
			}
			
		}
		
		//Sort values so that they are in ascending order when referenced in the gageValues array as in the flood slider
		valuesSort();
		
		for each (var floodGraphic:Graphic in  queryGraphicsLayer.graphicProvider)
		{	
			var graphicID:String = floodGraphic.id;
			var tempValue:Number = gageValues.getItemAt(0).gageValue;
			var id:String;
			
			id = siteNo + tempValue.toFixed(2);
			
			if (graphicID.match(siteNo + tempValue.toFixed(2)) != null) {
				graphicIDArray = graphicID.split(siteNo + tempValue.toFixed(2));
				break;
			}
		}
		
		for (var i:int; i < gridInfos.length; i++) {
			if (gridInfos[i].shortname == currentShortName && int(gridInfos[i].gridid) == int(graphicIDArray[1])) {
				gridLayerIndex = gridInfos[i].index;
				gridLayerIndexArrColl.addItem(gridInfos[i].index);
			} else if (gridInfos[i].shortname == currentShortName && gridInfos[i].gridid == graphicIDArray[1]+'b') {
				gridLayerIndex = gridInfos[i].index;
				gridLayerIndexArrColl.addItem(gridInfos[i].index);
			}
		}
		
		//gridsReset(false, gridLayerIndex);
		
		if (int(siteNo) == 0) {
			floodExtentsDyn.layerDefinitions = [
				"(USGSID LIKE '%" + siteNo + "%' AND STAGE = " + gageValues[0].gageValue + ")"
			];
		} else {
			floodExtentsDyn.layerDefinitions = [
				"(USGSID LIKE '%" + int(siteNo) + "%' AND STAGE = " + gageValues[0].gageValue + ")"
			];
		}
		floodExtentsDyn.refresh();
		
		
		if (int(siteNo) == 0) {
			floodBreachDyn.layerDefinitions = [
				"(USGSID LIKE '%" + siteNo + "%' AND STAGE = " + gageValues[0].gageValue + ")"
			];
		} else {
			floodBreachDyn.layerDefinitions = [
				"(USGSID LIKE '%" + int(siteNo) + "%' AND STAGE = " + gageValues[0].gageValue + ")"
			];
		}
		floodBreachDyn.refresh();
		
		trace(gageValues[0].gageValue);
		trace(floodExtentsDyn.layerDefinitions[0]);
		
		supplementalLayers.layerDefinitions = 
			[
				"USGSID = '"+siteNo+"' AND MULTI_SITE = 0",
				"USGSID = '"+siteNo+"' AND MULTI_SITE = 0"
			];
			
		supplementalLayers.refresh();
		supplementalLayers.visible = true;
		floodExtentLegend.visible = true;
		breachLegend.visible = true;
		
		currentStage = gageValues.getItemAt(0).gageValue;
		currentElev = altitudeValues.getItemAt(0).altitudeValue;
		currentDischarge = dischargeValues.getItemAt(0).dischargeValue;
		
		hasSuppLayerCheck(siteNo);
		
		/*for each (var floodGraphic:Graphic in queryGraphicsLayer.graphicProvider)
		{	
			var graphicID:String = floodGraphic.attributes.USGSID + floodGraphic.attributes.STAGE.toFixed(2) + floodGraphic.attributes.GRIDID;
			if (graphicID.match(siteNo + gageValues.getItemAt(initFloodSliderValue).gageValue) != null) {
				floodGraphic.visible = true;
			} else {
				floodGraphic.visible = false;
			}
			
		}*/
		
		
		function valuesSort():void {
			//sort gage heights
			var sortField:SortField = new SortField();
			sortField.name = "gageValue";
			sortField.numeric = true;
			
			var numericSort:Sort = new Sort();
			numericSort.fields = [sortField];
			
			gageValues.sort = numericSort;
			gageValues.refresh();
			
			//sort altitudes
			sortField = new SortField();
			sortField.name = "altitudeValue";
			sortField.numeric = true;
			
			numericSort = new Sort();
			numericSort.fields = [sortField];
			
			altitudeValues.sort = numericSort;
			altitudeValues.refresh();
			
			//sort discharge (qcfs)
			sortField = new SortField();
			sortField.name = "dischargeValue";
			sortField.numeric = true;
			
			numericSort = new Sort();
			numericSort.fields = [sortField];
			
			dischargeValues.sort = numericSort;
			dischargeValues.refresh();
		}
			
	}
	
	private function hasSuppLayerCheck(siteNo:String):void {
		var suppParams:FindParameters = new FindParameters();
		suppParams.searchText = siteNo;
		suppParams.layerIds = [0,1];
		suppParams.returnGeometry = false;
		var suppFindTask:FindTask = new FindTask(supplementalLayers.url);
		suppFindTask.addEventListener(FindEvent.EXECUTE_COMPLETE, getResults);
		suppFindTask.execute(suppParams);
		
		function getResults(event:FindEvent):void {
			if (event.findResults.length == 0) {
				supplementalLayersLegend.visible = false;
			} else {
				supplementalLayersLegend.visible = true;
			}
		}
	}
	

	private function floodMultiResult(featureSet:FeatureSet, token:Object = null):void
	{
		floodExisting = new Object();
		getGridInfo();
		siteNo = featureSet.features[0].attributes.USGSID_1;
		siteNo_2 = featureSet.features[0].attributes.USGSID_2;
		
		if (currentTimeStamp != token.jobTime) { return };
		
		libraryEnvQuery.geometry = map.extent;
		libraryEnvQuery.where = "(USGSID_1 LIKE '%" + int(siteNo) + "%' AND STAGE_1 = " + featureSet.features[0].attributes.STAGE_1 + " AND USGSID_2 LIKE '%" + int(siteNo_2) + "%' AND STAGE_2 = " + featureSet.features[0].attributes.STAGE_2 + ")";
		
		floodMultiTask.execute(libraryEnvQuery, new AsyncResponder(libEnvResult, infoFault, {type: 'libEnvQueryMulti'}));
		
		for each (var floodGraphic:Graphic in featureSet.features)
		{	
			var graphicID:String = siteNo + floodGraphic.attributes.STAGE_1.toFixed(2) + floodGraphic.attributes.STAGE_2.toFixed(2) + floodGraphic.attributes.GRIDID;
			gagePairs.addItem({STAGE_1: floodGraphic.attributes.STAGE_1.toFixed(2), STAGE_2: floodGraphic.attributes.STAGE_2.toFixed(2)});
			
			var i:int;
			var flag:Boolean = false;
			
			for (i=0;i<gageValues.length;i++) {
				if (gageValues.getItemAt(i)["gageValue"] == floodGraphic.attributes.STAGE_1.toFixed(2)) {
					flag = true;
				}
			}
			if (flag == false) {
				gageValues.addItem({gageValue:floodGraphic.attributes.STAGE_1.toFixed(2)});
			}
			
			flag = false;
			
			for (i=0;i<altitudeValues.length;i++) {
				if (altitudeValues.getItemAt(i)["altitudeValue"] == floodGraphic.attributes.ELEV_1.toFixed(2)) {
					flag = true;
				}
			}
			if (flag == false) {
				altitudeValues.addItem({altitudeValue:floodGraphic.attributes.ELEV_1.toFixed(2)});
			}
			
			flag = false;
			
			for (i=0;i<gageValues2.length;i++) {
				if (gageValues2.getItemAt(i)["gageValue"] == floodGraphic.attributes.STAGE_2.toFixed(2)) {
					flag = true;
				}
			}
			if (flag == false) {
				gageValues2.addItem({gageValue:floodGraphic.attributes.STAGE_2.toFixed(2)});
			}
			flag = false;
			
			for (i=0;i<altitudeValues2.length;i++) {
				if (altitudeValues2.getItemAt(i)["altitudeValue"] == floodGraphic.attributes.ELEV_2.toFixed(2)) {
					flag = true;
				}
			}
			if (flag == false) {
				altitudeValues2.addItem({altitudeValue:floodGraphic.attributes.ELEV_2.toFixed(2)});
			}
			
			if (!floodExisting[graphicID])
			{
				floodExisting[graphicID] = 1;
				floodGraphic.symbol = aQuerySym;
				floodGraphic.id = graphicID;
				floodGraphic.visible = false;
				if(gridInfos.length > 0) {
					floodGraphic.toolTip = "Click for estimated water depth";
				}
				queryGraphicsLayer.add(floodGraphic);
			}
			
		}
		
		var sortField:SortField = new SortField();
		sortField.name = "gageValue";
		sortField.numeric = true;
		
		var numericSort:Sort = new Sort();
		numericSort.fields = [sortField];
		
		gageValues.sort = numericSort;
		gageValues.refresh();
		gageValues2.sort = numericSort;
		gageValues2.refresh();
		
		sortField = new SortField();
		sortField.name = "altitudeValue";
		sortField.numeric = true;
		
		numericSort = new Sort();
		numericSort.fields = [sortField];
		
		altitudeValues.sort = numericSort;
		altitudeValues.refresh();
		altitudeValues2.sort = numericSort;
		altitudeValues2.refresh();
		
		for each (var graphic:Graphic in queryGraphicsLayer.graphicProvider)
		{
			if (graphic.id.match(siteNo + gageValues.getItemAt(0).gageValue + gageValues2.getItemAt(0).gageValue) != null) {
				graphic.visible = true;
			} else {
				graphic.visible = false;
			}
		}
		
		if (gageValues.length != 0 && gageValues2.length != 0) {
			sliderGageValue = gageValues[0].gageValue;
			sliderGageValue_2 = gageValues2[0].gageValue;
			
			//gridsReset(false, gridLayerIndex, gridLayerIndexArrColl);
			
			floodMultiSitesDyn.layerDefinitions = [
				"(USGSID_1 LIKE '%" + int(siteNo) + "%' AND STAGE_1 = " + gageValues[0].gageValue + " AND USGSID_2 LIKE '%" + int(siteNo_2) + "%' AND STAGE_2 = " + gageValues2[0].gageValue + ")"
			];
			floodMultiSitesDyn.refresh();
			
			
			//To fix by renaming the fields in the service :test :fix :dontforgetthis
			floodBreachMultiDyn.layerDefinitions = [
				"(SITE_NO_1 LIKE '%" + int(siteNo) + "%' AND STAGE_1 = " + gageValues[0].gageValue + " AND SITE_NO_2 LIKE '%" + int(siteNo_2) + "%' AND STAGE_2 = " + gageValues2[0].gageValue + ")"
			];
			floodBreachMultiDyn.refresh();
			
			supplementalLayers.layerDefinitions = 
			[
				"(USGSID LIKE '%"+int(siteNo)+"%' AND MULTI_SITE = 1) OR (USGSID LIKE '%"+int(siteNo_2)+"%' AND MULTI_SITE = 1)",
				"(USGSID LIKE '%"+int(siteNo)+"%' AND MULTI_SITE = 1) OR (USGSID LIKE '%"+int(siteNo_2)+"%' AND MULTI_SITE = 1)"
			];
			
			supplementalLayers.refresh();
			supplementalLayers.visible = true;
			
			floodExtentLegend.visible = true;
			breachLegend.visible = true;
		}
		
	}
	
	private function floodMultiThreeSiteResult(featureSet:FeatureSet, token:Object = null):void
	{
		floodExisting = new Object();
		//trace(token.ordinal);
		getGridInfo();
		//getGridInfoThree();
		siteNo = featureSet.features[0].attributes.USGSID_1;
		siteNo_2 = featureSet.features[0].attributes.USGSID_2;
		if (currentTimeStamp != token.jobTime) { return };
		//trace("into " + token.ordinal);
		
		libraryEnvQuery.geometry = map.extent;
		libraryEnvQuery.where = "(USGSID_1 LIKE '%" + int(siteNo) + "%' AND STAGE_1 = " + featureSet.features[0].attributes.STAGE_1 + " AND USGSID_2 LIKE '%" + int(siteNo_2) + "%' AND STAGE_2 = " + featureSet.features[0].attributes.STAGE_2 + ")";
		
		floodMultiTask.execute(libraryEnvQuery, new AsyncResponder(libEnvResult, infoFault, {type: 'libEnvQueryMultiThis'}));
		
		for each (var floodGraphic:Graphic in featureSet.features)
		{	
			if (token.ordinal == 1) {
				makeGagePairs(floodGraphic,gagePairs,gageValues,gageValues2,altitudeValues,altitudeValues2);
			} else if (token.ordinal == 2) {
				makeGagePairs(floodGraphic,gagePairs2,gageValues2,gageValues3,altitudeValues2,altitudeValues3);
			}
			//trace('looped once');
		}
		
		function makeGagePairs(floodGraphic:Graphic,gagePairs:ArrayCollection,gageValues:ArrayCollection,gageValues2:ArrayCollection,altitudeValues:ArrayCollection,altitudeValues2:ArrayCollection):void {
			var graphicID:String = siteNo + floodGraphic.attributes.STAGE_1.toFixed(2) + floodGraphic.attributes.STAGE_2.toFixed(2) + floodGraphic.attributes.GRIDID;
			gagePairs.addItem({STAGE_1: floodGraphic.attributes.STAGE_1.toFixed(2), STAGE_2: floodGraphic.attributes.STAGE_2.toFixed(2), GRIDID: floodGraphic.attributes.GRIDID});
			
			var i:int;
			var flag:Boolean = false;
			//trace('in make gage pairs');
			
			if (token.ordinal == 1) {
				for (i=0;i<gageValues.length;i++) {
					if (gageValues.getItemAt(i)["gageValue"] == floodGraphic.attributes.STAGE_1) {
						flag = true;
					}
				}
				if (flag == false) {
					gageValues.addItem({gageValue:floodGraphic.attributes.STAGE_1});
				}
				
				flag = false;
				
				for (i=0;i<altitudeValues.length;i++) {
					if (altitudeValues.getItemAt(i)["altitudeValue"] == floodGraphic.attributes.ELEV_1) {
						flag = true;
					}
				}
				if (flag == false) {
					altitudeValues.addItem({altitudeValue:floodGraphic.attributes.ELEV_1});
				}
			}	
			
			flag = false;
			
			for (i=0;i<gageValues2.length;i++) {
				if (gageValues2.getItemAt(i)["gageValue"] == floodGraphic.attributes.STAGE_2) {
					flag = true;
				}
			}
			if (flag == false) {
				gageValues2.addItem({gageValue:floodGraphic.attributes.STAGE_2});
			}
			flag = false;
			
			for (i=0;i<altitudeValues2.length;i++) {
				if (altitudeValues2.getItemAt(i)["altitudeValue"] == floodGraphic.attributes.ELEV_2) {
					flag = true;
				}
			}
			if (flag == false) {
				altitudeValues2.addItem({altitudeValue:floodGraphic.attributes.ELEV_2});
			}
			
			if (!floodExisting[graphicID])
			{
				floodExisting[graphicID] = 1;
				floodGraphic.symbol = aQuerySym;
				floodGraphic.id = graphicID;
				floodGraphic.visible = false;
				if(gridInfos.length > 0) {
					floodGraphic.toolTip = "Click for estimated water depth";
				}
				queryGraphicsLayer.add(floodGraphic);
			}
			//trace('end makegagepairs');
		}
		
		var sortField:SortField = new SortField();
		sortField.name = "gageValue";
		sortField.numeric = true;
		
		var numericSort:Sort = new Sort();
		numericSort.fields = [sortField];
		
		gageValues.sort = numericSort;
		gageValues.refresh();
		gageValues2.sort = numericSort;
		gageValues2.refresh();
		gageValues3.sort = numericSort;
		gageValues3.refresh();
		
		sortField = new SortField();
		sortField.name = "altitudeValue";
		sortField.numeric = true;
		
		numericSort = new Sort();
		numericSort.fields = [sortField];
		
		altitudeValues.sort = numericSort;
		altitudeValues.refresh();
		altitudeValues2.sort = numericSort;
		altitudeValues2.refresh();
		altitudeValues3.sort = numericSort;
		altitudeValues3.refresh();
		
		if (gageValues.length != 0 && gageValues2.length != 0 && gageValues3.length != 0) {
			sliderGageValue = gageValues[0].gageValue;
			sliderGageValue_2 = gageValues2[0].gageValue;
			sliderGageValue_3 = gageValues3[0].gageValue;
			
			//gridsReset(false, gridLayerIndex, gridLayerIndexArrColl);
			
			floodMultiSitesDyn.layerDefinitions = [
				"(USGSID_1 LIKE '%" + int(siteNo) + "%' AND STAGE_1 = " + gageValues[0].gageValue + " AND USGSID_2 LIKE '%" + int(siteNo_2) + "%' AND STAGE_2 = " + gageValues2[0].gageValue + ")"
			];
			floodMultiSitesDyn2.layerDefinitions = [
				"(USGSID_1 LIKE '%" + int(siteNo_2) + "%' AND STAGE_1 = " + gageValues2[0].gageValue + " AND USGSID_2 LIKE '%" + int(siteNo_3) + "%' AND STAGE_2 = " + gageValues3[0].gageValue + ")"
			];
			floodMultiSitesDyn.refresh();
			floodMultiSitesDyn2.refresh();
			
			floodExtentLegend.visible = true;
			breachLegend.visible = true;
		}
		
	}
	
	private function floodMultiAllThreeSiteResult(featureSet:FeatureSet, token:Object = null):void
	{
		floodExisting = new Object();
		//trace(token.ordinal);
		getGridInfo();
		siteNo = featureSet.features[0].attributes.USGSID_1;
		siteNo_2 = featureSet.features[0].attributes.USGSID_2;
		siteNo_3 = featureSet.features[0].attributes.USGSID_3;
		if (currentTimeStamp != token.jobTime) { return };
		//trace("into " + token.ordinal);
		
		libraryEnvQuery.geometry = map.extent;
		libraryEnvQuery.where = "(USGSID_1 LIKE '%" + int(siteNo) + "%' AND STAGE_1 = " + featureSet.features[0].attributes.STAGE_1 + " AND USGSID_2 LIKE '%" + int(siteNo_2) + "%' AND STAGE_2 = " + featureSet.features[0].attributes.STAGE_2 + ")";
		
		floodMultiAllThreeSiteTask.execute(libraryEnvQuery, new AsyncResponder(libEnvResult, infoFault, {type: 'libEnvQueryAllThree'}));
		
		for each (var floodGraphic:Graphic in featureSet.features)
		{	
			var graphicID:String = siteNo + floodGraphic.attributes.STAGE_1.toFixed(2) + floodGraphic.attributes.STAGE_2.toFixed(2) + floodGraphic.attributes.STAGE_3.toFixed(2) + floodGraphic.attributes.GRIDID;
			gageSet.addItem({STAGE_1: floodGraphic.attributes.STAGE_1.toFixed(2), STAGE_2: floodGraphic.attributes.STAGE_2.toFixed(2), STAGE_3: floodGraphic.attributes.STAGE_3.toFixed(2), GRIDID: floodGraphic.attributes.GRIDID});
			
			var i:int;
			var flag:Boolean = false;
			//trace('in make gage sets');
			
			if (token.ordinal == 1) {
				for (i=0;i<gageValues.length;i++) {
					if (gageValues.getItemAt(i)["gageValue"] == floodGraphic.attributes.STAGE_1) {
						flag = true;
					}
				}
				if (flag == false) {
					gageValues.addItem({gageValue:floodGraphic.attributes.STAGE_1});
				}
				
				flag = false;
				
				for (i=0;i<altitudeValues.length;i++) {
					if (altitudeValues.getItemAt(i)["altitudeValue"] == floodGraphic.attributes.ELEV_1) {
						flag = true;
					}
				}
				if (flag == false) {
					altitudeValues.addItem({altitudeValue:floodGraphic.attributes.ELEV_1});
				}
			}	
			
			flag = false;
			
			for (i=0;i<gageValues2.length;i++) {
				if (gageValues2.getItemAt(i)["gageValue"] == floodGraphic.attributes.STAGE_2) {
					flag = true;
				}
			}
			if (flag == false) {
				gageValues2.addItem({gageValue:floodGraphic.attributes.STAGE_2});
			}
			flag = false;
			
			for (i=0;i<altitudeValues2.length;i++) {
				if (altitudeValues2.getItemAt(i)["altitudeValue"] == floodGraphic.attributes.ELEV_2) {
					flag = true;
				}
			}
			if (flag == false) {
				altitudeValues2.addItem({altitudeValue:floodGraphic.attributes.ELEV_2});
			}
			
			flag = false;
			
			for (i=0;i<gageValues3.length;i++) {
				if (gageValues3.getItemAt(i)["gageValue"] == floodGraphic.attributes.STAGE_3) {
					flag = true;
				}
			}
			if (flag == false) {
				gageValues3.addItem({gageValue:floodGraphic.attributes.STAGE_3});
			}
			flag = false;
			
			for (i=0;i<altitudeValues3.length;i++) {
				if (altitudeValues3.getItemAt(i)["altitudeValue"] == floodGraphic.attributes.ELEV_3) {
					flag = true;
				}
			}
			if (flag == false) {
				altitudeValues3.addItem({altitudeValue:floodGraphic.attributes.ELEV_3});
			}  
			
			if (!floodExisting[graphicID])
			{
				floodExisting[graphicID] = 1;
				floodGraphic.symbol = aQuerySym;
				floodGraphic.id = graphicID;
				floodGraphic.visible = false;
				if(gridInfos.length > 0) {
					floodGraphic.toolTip = "Click for estimated water depth";
				}
				queryGraphicsLayer.add(floodGraphic);
			}
			//trace('end makegagesets');
			
		}
		
		var sortField:SortField = new SortField();
		sortField.name = "gageValue";
		sortField.numeric = true;
		
		var numericSort:Sort = new Sort();
		numericSort.fields = [sortField];
		
		gageValues.sort = numericSort;
		gageValues.refresh();
		gageValues2.sort = numericSort;
		gageValues2.refresh();
		gageValues3.sort = numericSort;
		gageValues3.refresh();
		
		sortField = new SortField();
		sortField.name = "altitudeValue";
		sortField.numeric = true;
		
		numericSort = new Sort();
		numericSort.fields = [sortField];
		
		altitudeValues.sort = numericSort;
		altitudeValues.refresh();
		altitudeValues2.sort = numericSort;
		altitudeValues2.refresh();
		altitudeValues3.sort = numericSort;
		altitudeValues3.refresh();
		
		if (gageValues.length != 0 && gageValues2.length != 0 && gageValues3.length != 0) {
			sliderGageValue = gageValues[0].gageValue;
			sliderGageValue_2 = gageValues2[0].gageValue;
			sliderGageValue_3 = gageValues3[0].gageValue;
			
			//gridsReset(false, gridLayerIndex, gridLayerIndexArrColl);
			
			floodThreeSitesDyn.layerDefinitions = [
				"(USGSID_1 LIKE '%" + int(siteNo) + "%' AND STAGE_1 = " + gageValues[0].gageValue + " AND USGSID_2 LIKE '%" + int(siteNo_2) + "%' AND STAGE_2 = " + gageValues2[0].gageValue + " AND USGSID_3 LIKE '%" + int(siteNo_3) + "%' AND STAGE_3 = " + gageValues3[0].gageValue + ")"
			];
			floodThreeSitesDyn.refresh();
			
			floodExtentLegend.visible = true;
			breachLegend.visible = true;
		}
		
	}
	
	
	
	/* End query tooltip methods */
	
	/* Disclaimer pop up box handling methods */
	private function popUpHandler(event:FlexEvent):void {
		if (moreInfo.visible == true && _queryWindow != null) {
			_queryWindow.visible = false;
		} else if (moreInfo.visible == false && _queryWindow != null) {
			_queryWindow.visible = true;
		}
	}
	
	/* End disclaimer pop up box handling methods */
	
	private function getGridInfo():void
	{
		var gridServ:Array;
		switch (grid_serv) {
			case "1":
				gridServ = grid1Infos;
				break;
			case "2":
				gridServ = grid2Infos;
				break;
			case "3":
				gridServ = grid3Infos;
				break;
			case null:
				gridServ = null;
				break;
		}
		
		if (gridServ != null) {
			var id:int;
			var shortName:String;
			var gridID:String;
			for (var i:int = 0; i < gridServ.length; i++) {
				var tempGridInfo:Array = gridServ[i].name.split('_');
				shortName = tempGridInfo[0];
				gridID = tempGridInfo[1];
				id = gridServ[i].layerId;
				if (shortName == currentShortName || shortName == "omonash" || shortName == "nashbor") {
					/*var tempName:String = fimi_grids.layerInfos[i].name;
					var tempGage:String = tempGridInfo[1] + '.' + tempGridInfo[2];
					var tempGageNumber:Number = parseFloat(tempGage);
					gridInfos.addItem({index: id, name: tempName, gage: tempGageNumber.toFixed(2)});*/
					gridInfos.addItem({index: id, shortname: shortName, gridid: gridID});
				}
			}
		}
		
	}
	
	public function getGridInfoThree():void
	{
		var gridServ:Array;
		switch (grid_serv) {
			case "1":
				gridServ = grid1Infos;
				break;
			case "2":
				gridServ = grid2Infos;
				break;
			case "3":
				gridServ = grid3Infos;
				break;
			case null:
				gridServ = null;
				break;
		}
		
		if (gridServ != null) {
			var id:int;
			var shortName:String;
			var gridID:Number;
			for each (var item:String in currentShortNames) {
				for (var i:int = 0; i < gridServ.length; i++) {
					var tempGridInfo:Array = gridServ[i].name.split('_');
					shortName = tempGridInfo[0];
					gridID = int(tempGridInfo[1]);
					id = gridServ[i].layerId;
					trace(shortName);
					if (shortName == currentShortName) {
						gridInfos.addItem({index: id, shortname: shortName, gridid: gridID});
					}
				}
			}
		}
		trace('here');
	}
	
	private function onAHPSSitesToggle(event:MouseEvent):void {
		if (ahpsSitesToggle.selected == true && ahpsForecastNormalToggle.selected == false && ahpsForecastMinorToggle.selected == false && ahpsForecastModerateToggle.selected == false && ahpsForecastMajorToggle.selected == false && ahpsForecastOldToggle.selected == false && ahpsForecastActionToggle.selected == false) {
			ahpsForecastNormalToggle.selected = true;
			ahpsForecastMinorToggle.selected = true; 
			ahpsForecastModerateToggle.selected = true;
			ahpsForecastMajorToggle.selected = true;
			ahpsForecastOldToggle.selected = true;
			ahpsForecastActionToggle.selected = true;
			updateAHPSLayer();
		} else if (ahpsSitesToggle.selected == false) {
			ahpsForecastNormalToggle.selected = false;
			ahpsForecastMinorToggle.selected = false; 
			ahpsForecastModerateToggle.selected = false;
			ahpsForecastMajorToggle.selected = false;
			ahpsForecastOldToggle.selected = false;
			ahpsForecastActionToggle.selected = false;
			updateAHPSLayer();
		}
	}
	
	private function onAHPSLayerToggle(event:MouseEvent):void {
		updateAHPSLayer();
	}
	
	private function updateAHPSLayer():void {
		var ahpsLayerDefs:String = "status = '-1'";
		ahpsForecast.visible = true;
		
		if (ahpsInfoLayer.graphicProvider.length > 0) {
			var infoBoxType:String = ahpsInfoLayer.graphicProvider[0].attributes.stage;
			var infoBoxRemain:int = 0;
		}
		
		if (ahpsForecastNormalToggle.selected) {
			ahpsSitesToggle.selected = true;
			if (infoBoxType == 'normal') { infoBoxRemain = 1 }
			ahpsLayerDefs += " OR status = 'normal' OR status = 'no_flooding'";
		}
		if (ahpsForecastMinorToggle.selected) {
			ahpsSitesToggle.selected = true;
			if (infoBoxType == 'minor') { infoBoxRemain = 1 }
			ahpsLayerDefs += " OR status = 'minor'";
		}
		if (ahpsForecastModerateToggle.selected) {
			ahpsSitesToggle.selected = true;
			if (infoBoxType == 'moderate') { infoBoxRemain = 1 }
			ahpsLayerDefs += " OR status = 'moderate'";
		}
		if (ahpsForecastMajorToggle.selected) {
			ahpsSitesToggle.selected = true;
			if (infoBoxType == 'major') { infoBoxRemain = 1 }
			ahpsLayerDefs += " OR status = 'major'";
		}
		if (ahpsForecastOldToggle.selected) {
			ahpsSitesToggle.selected = true;
			if (infoBoxType == 'old') { infoBoxRemain = 1 }
			ahpsLayerDefs += " OR status = 'old'";
		}
		if (ahpsForecastActionToggle.selected) {
			ahpsSitesToggle.selected = true;
			if (infoBoxType == 'action') { infoBoxRemain = 1 }
			ahpsLayerDefs += " OR status = 'action'";
		}
		
		if (infoBoxRemain == 0) {
			ahpsInfoLayer.clear();
		}
		
		ahpsForecast.layerDefinitions = 
		[
			ahpsLayerDefs
		];
		
	}
	
	private function baseSwitch(event:FlexEvent):void            
	{                
		var tiledLayer:TiledMapServiceLayer = event.target as TiledMapServiceLayer;                
		if (tiledLayer.tileInfo != null && tiledLayer.id != "labelsMapLayer") {
			lods = tiledLayer.tileInfo.lods.slice(0,18);
			map.lods = lods;
			//map.lods = tiledLayer.tileInfo.lods;
		}
	}
	
	
	
	
	/* Geo-coding methods */
	//Original code taken from ESRI sample: http://resources.arcgis.com/en/help/flex-api/samples/index.html#/Geocode_an_address/01nq00000068000000/
	//Adjusted for handling lat/lng vs. lng/lat inputs
	private function geoCode(searchCriteria:String):void
	{
		var parameters:AddressToLocationsParameters = new AddressToLocationsParameters();
		//parameters such as 'SingleLine' are dependent upon the locator service used.
		parameters.address = { SingleLine: searchCriteria };
		
		// Use outFields to get back extra information
		// The exact fields available depends on the specific locator service used.
		parameters.outFields = [ "*" ];
		
		locator.addressToLocations(parameters, new AsyncResponder(onResult, onFault));
		function onResult(candidates:Array, token:Object = null):void
		{
			if (candidates.length > 0)
			{
				var addressCandidate:AddressCandidate = candidates[0];
				
				//map.centerAt(addressCandidate.location);
				
				map.extent = com.esri.ags.utils.WebMercatorUtil.geographicToWebMercator(new Extent(addressCandidate.attributes.Xmin, addressCandidate.attributes.Ymin,  addressCandidate.attributes.Xmax, addressCandidate.attributes.Ymax, map.spatialReference)) as Extent;
				
				// Zoom to an appropriate level
				// Note: your attribute and field value might differ depending on which Locator you are using...
				/*if (addressCandidate.attributes.Loc_name.indexOf("AddressPoint") != -1) // US_RoofTop
				{
					map.scale = 9028;
				}
				else if (addressCandidate.attributes.Loc_name.indexOf("StreetAddress") != -1)
				{
					map.scale = 18056;
				}
				else if (addressCandidate.attributes.Loc_name.indexOf("StreetName") != -1) // US_Streets, CAN_Streets, CAN_StreetName, EU_Street_Addr* or EU_Street_Name*
				{
					map.scale = 36112;
				}
				else if (addressCandidate.attributes.Loc_name.indexOf("Postal") != -1
					|| addressCandidate.attributes.Loc_name.indexOf("PostalExt") != -1) // US_ZIP4, CAN_Postcode
				{
					map.scale = 144448;
				}
				else if (addressCandidate.attributes.Loc_name.indexOf("Postal") != -1) // US_Zipcode
				{
					map.scale = 144448;
				}
				else if (addressCandidate.attributes.Loc_name.indexOf("AdminPlaces") != -1) // US_CityState, CAN_CityProv
				{
					map.scale = 288895;
				}
				else if (addressCandidate.attributes.Loc_name.indexOf("WorldGazetteer") != -1) // US_CityState, CAN_CityProv
				{
					map.scale = 577791;
				}
				else
				{
					map.scale = 1155581;
				}*/
				//myInfo.textFlow = TextFlowUtil.importFromString("<span fontWeight='bold'>Found:</span><br/>" + addressCandidate.address.toString()); // formated address
			}
			else
			{
				Alert.show("Sorry, couldn't find a location for this address"
					+ "\nAddress: " + searchCriteria);
			}
		}
		
		function onFault(info:Object, token:Object = null):void
		{
			//myInfo.htmlText = "<b>Failure</b>" + info.toString();
			Alert.show("Failure: \n" + info.toString());
		}
	}
	
	/* End geo-coding methods */
	
	
	
	/* Full screen methods */
	public function isFullScreen() : Boolean
	{	
		return (this.stage.displayState == StageDisplayState.FULL_SCREEN);
	}
	
	public function goFullScreen():void
	{
		try {
			this.stage.displayState = StageDisplayState.FULL_SCREEN;
		}
		catch (e:Error)
		{
			Alert.show(e.toString() + this.stage.displayState, "Error");
		}
	}
	
	public function exitFullScreen():void
	{
		this.stage.displayState = StageDisplayState.NORMAL;
	}
	
	public function toggleFullScreen():void
	{
		//stage.addEventListener(FullScreenEvent.FULL_SCREEN, handleFullScreen);
		if ( !isFullScreen() ) {
			goFullScreen();
		} else {
			exitFullScreen();
		}
	}
	
	/* End full screen methods */
	
	
	
	
	
/*	public function toggleOverlays():void {
		if (header.visible) {
			header.visible = false;
			headerLogo.visible = false;
			baseLayers.visible = false;
			navigation.visible = false;
			geocoder.visible = false;
			controlLayers.visible = false;
			//printButton.visible = false;
		} else {
			header.visible = true;
			headerLogo.visible = true;
			baseLayers.visible = true;
			navigation.visible = true;
			geocoder.visible = true;
			controlLayers.visible = true;
			//printButton.visible = true;					
		}
	}
*/	
	
	//function to set up mapper for PDF creation and print job
	/*public function startPrint(pEvt:MouseEvent):void
	{
	toggleOverlays();
	printFormBox.fadeIn(1000);				
	
	
	Alert.show("Position and scale the map in the window provided to ensure the printed product will contain the desired area.");
	
	}*/
	
	//Function to close print form without executing pdf creation. Returns map to previous state.
	public function printFormClose():void
	{
		
		map.x = 0;
		map.y = 0;
		map.percentHeight = 100;
		map.percentWidth = 100;
	}
	
	private function animateOver(event:MouseEvent):void
	{
		var siteGlow:Glow = new Glow();
		siteGlow.target = event.target;
		siteGlow.blurXTo = 50;
		siteGlow.blurYTo = 50;
		siteGlow.color = 0xFFFF00;
		siteGlow.duration = 1000;
		siteGlow.repeatCount = 3;
		
		siteGlow.play();
		
		
		
		event.target.addEventListener(MouseEvent.MOUSE_OUT, animateOut);
		
		function animateOut(event:MouseEvent):void
		{
			siteGlow.end();
		}
	}
	
	private function onRightClick():void {
		//Recenter at mouse location
		var cursorLocation:Point = new Point(contentMouseX, contentMouseY);
		map.centerAt(map.toMap(cursorLocation));
		//Zoom out
		map.zoomOut();
	}

	public function handleWheel(event:Object): void {	
		var obj:InteractiveObject = null;	
		var objects:Array = getObjectsUnderPoint(new Point(event.x, event.y));	
		for (var i:int = objects.length - 1; i >= 0; i--) {
			if (objects[i] is InteractiveObject) {			
				obj = objects[i] as InteractiveObject;			
				break;		
			} else {			
				if (objects[i] is Shape && (objects[i] as Shape).parent) {				
					obj = (objects[i] as Shape).parent;				
					break;			
				}		
			}	
		}	if (obj) {		
			var mEvent:MouseEvent = new MouseEvent(MouseEvent.MOUSE_WHEEL, true, false, event.x, event.y, obj, event.ctrlKey, event.altKey, event.shiftKey, false, -Number(event.delta));		
			obj.dispatchEvent(mEvent);	
		}
	}
	
	protected function showUSGSPopUpBox(event:MouseEvent, popupName:String):void
	{
		popUpBoxes[ popupName ] = PopUpManager.createPopUp(this, Group) as Group;
		popUpBoxes[ popupName ].addElement( this[ popupName ] );
		popUpBoxes[ popupName ].x = 20
		popUpBoxes[ popupName ].y = 20
	}
	
	
	protected function popUp_mouseOutHandler(event:MouseEvent, popupName:String):void
	{
		if (!popUpBoxes[ popupName ].hitTestPoint(event.stageX, event.stageY, true)) {
			PopUpManager.removePopUp(popUpBoxes[ popupName ]);
		}
	}
	
	
	///TEST PRINT STUFF
	
	private function printBtn_clickHandler(event:MouseEvent):void
	{
		if (printLoadingScreen.visible == false) {
			
			testMap.extent = map.extent;
			
			floodExtentPrint.layerDefinitions = floodExtentsDyn.layerDefinitions;
			floodBreachPrint.layerDefinitions = floodBreachDyn.layerDefinitions;
			floodExtentMultiPrint.layerDefinitions = floodMultiSitesDyn.layerDefinitions;
			floodBreachMultiPrint.layerDefinitions = floodBreachMultiDyn.layerDefinitions;
			floodThreeSitesDyn.layerDefinitions = floodThreeSitesDynPrint.layerDefinitions;
			supplementalLayersPrint.layerDefinitions = supplementalLayers.layerDefinitions;
			
			var newPrintTask:PrintTask = new PrintTask();
			newPrintTask.addEventListener(PrintEvent.EXECUTE_COMPLETE, printTask_executeCompleteHandler);
			newPrintTask.addEventListener(FaultEvent.FAULT, function(event:FaultEvent):void {
				Alert.show("An errored has occurred while attempting to print the map. Please try again.");
				printLoadingScreen.visible = false;
			});
			//newPrintTask.addEventListener(PrintEvent.GET_RESULT_DATA_COMPLETE, printTask_getResultDataCompleteHandler);
			//newPrintTask.addEventListener(PrintEvent.JOB_COMPLETE, printTask_jobCompleteHandler);
			newPrintTask.disableClientCaching = true;
			newPrintTask.url = resourceManager.getString('urls', 'printUrl');
			
			var siteStatePrint:String = "";
			siteStatePrint = stateArrayFix(siteState, / |-/);
			//siteStatePrint = stateArrayFix(siteState, "-");
			
			//Need to adapt code to capitalize both words if state has two words
			function stateArrayFix(siteStateIn:String, char:RegExp):String {
				var siteStateArray:Array = siteStateIn.split(char);
				var siteStateOut:String = "";
				for (var i:int = 0; i < siteStateArray.length; i++) {
					if (i != 0) {
						if (siteStateIn.split(" ").length > 1) {
							siteStateOut += " ";
						} else if (siteStateIn.split("-").length > 1) {
							siteStateOut += "-";
						}
					}
					siteStateOut += siteStateArray[i].charAt(0).toUpperCase() + siteStateArray[i].substr(1, siteStateArray[i].length-1).toLowerCase();
				}
				//var siteStateOut:String = siteState.charAt(0).toUpperCase() + siteState.substr(1, siteState.length-1).toLowerCase();	
				
				return siteStateOut;
			}
			
			if (series_num == null) {
				printParameters.customParameters.Map_Info = siteCommunity + ", " + siteStatePrint + "|" + siteNo + "|" + currentStage + "|" + currentReport + "|"
														+ authors + ", " + rep_date + ", " + title + ": " + rep_series + " " + series_num + ", " + add_info + "|" + currentElev + "|" 
														+ study_date;
			} else if (series_num.match("–") != null) {
				var seriesNumArray:Array = series_num.split("–");
				
				printParameters.customParameters.Map_Info = siteCommunity + ", " + siteStatePrint + "|" + siteNo + "|" + currentStage + "|" + currentReport + "|"
														+ authors + ", " + rep_date + ", " + title + ": " + rep_series + " " + seriesNumArray[0] + "-" + seriesNumArray[1] + ", " + add_info 
														+ "|" + currentElev + "|" + study_date;
			} else {
				printParameters.customParameters.Map_Info = siteCommunity + ", " + siteStatePrint + "|" + siteNo + "|" + currentStage + "|" + currentReport + "|"
														+ authors + ", " + rep_date + ", " + title + ": " + rep_series + " " + series_num + ", " + add_info + "|" + currentElev + "|" 
														+ study_date;
			}
			
			var siteDefExp:String = "";
			var siteToGage:String = "";
			if (multiSite == '0') {
				siteDefExp = "SITE_NO = '" + siteNo + "'";
				siteToGage = "Map corresponding to a Gage Height of " + currentStage + " feet and an Elevation of " + currentElev + " feet (NAVD 88)";
			} else if (multiSite == '1') {
				siteDefExp = "SITE_NO = '" + siteNo + "' OR SITE_NO = '" + siteNo_2 + "'";
				/*siteToGage = "Map corresponding to a Gage Height of " + gageValues.getItemAt(sliderValue).gageValue + " feet and an Elevation of " + altitudeValues.getItemAt(sliderValue).altitudeValue + " feet (NAVD 88) at " + siteNo + "\n" +
				"Map corresponding to a Gage Height of " + gageValues2.getItemAt(sliderValue_2).gageValue + " feet and an Elevation of " + altitudeValues2.getItemAt(sliderValue_2).altitudeValue + " feet (NAVD 88) at " + siteNo_2;*/
				//siteToGage = "Map corresponding to streamgage number " + siteNo + " at " + gageValues.getItemAt(sliderValue).gageValue + " feet and streamgage number " + siteNo_2 + " at " + gageValues2.getItemAt(sliderValue_2).gageValue + " feet";
				siteToGage = "Map corresponding to selected stages at following sites: " + gageValues.getItemAt(sliderValue).gageValue + " ft at " + siteNo + "; " + gageValues2.getItemAt(sliderValue_2).gageValue + " ft at " + siteNo_2;
			} else if (multiSite == '2') {
				siteDefExp = "SITE_NO = '" + siteNo + "' OR SITE_NO = '" + siteNo_2 + "' OR SITE_NO = '" + siteNo_3 + "'";
				/*siteToGage = "Map corresponding to a Gage Height of " + gageValues.getItemAt(sliderValue).gageValue + " feet and an Elevation of " + altitudeValues.getItemAt(sliderValue).altitudeValue + " feet (NAVD 88) at " + siteNo + "\n" +
				"Map corresponding to a Gage Height of " + gageValues2.getItemAt(sliderValue_2).gageValue + " feet and an Elevation of " + altitudeValues2.getItemAt(sliderValue_2).altitudeValue + " feet (NAVD 88) at " + siteNo_2;*/
				siteToGage = "<FNT size='7.5'>Map corresponding to streamgage number " + siteNo + " at " + gageValues.getItemAt(sliderValue).gageValue + " feet and streamgage number " + siteNo_2 + " at " + gageValues2.getItemAt(sliderValue_2).gageValue + " feet" +
				" and streamgage number " + siteNo_3 + " at " + gageValues3.getItemAt(sliderValue_3).gageValue + " feet</FNT>";
				siteToGage = "<FNT size='7.5'>Map corresponding to selected stages at following sites: " + gageValues.getItemAt(sliderValue).gageValue + " ft at " + siteNo + "; " + gageValues2.getItemAt(sliderValue_2).gageValue + " ft at " + siteNo_2 + "; " + gageValues3.getItemAt(sliderValue_3).gageValue + " ft at " + siteNo_3 + "</FNT>";
			} else if (multiSite == '3') {
				siteDefExp = "SITE_NO = '" + siteNo + "' OR SITE_NO = '" + siteNo_2 + "' OR SITE_NO = '" + siteNo_3 + "'";
				/*siteToGage = "Map corresponding to a Gage Height of " + gageValues.getItemAt(sliderValue).gageValue + " feet and an Elevation of " + altitudeValues.getItemAt(sliderValue).altitudeValue + " feet (NAVD 88) at " + siteNo + "\n" +
				"Map corresponding to a Gage Height of " + gageValues2.getItemAt(sliderValue_2).gageValue + " feet and an Elevation of " + altitudeValues2.getItemAt(sliderValue_2).altitudeValue + " feet (NAVD 88) at " + siteNo_2 + "\n" +
				"Map corresponding to a Gage Height of " + gageValues3.getItemAt(sliderValue_3).gageValue + " feet and an Elevation of " + altitudeValues3.getItemAt(sliderValue_3).altitudeValue + " feet (NAVD 88) at " + siteNo_3;*/
				siteToGage = "<FNT size='7.5'>Map corresponding to streamgage number " + siteNo + " at " + gageValues.getItemAt(sliderValue).gageValue + " feet and streamgage number " + siteNo_2 + " at " + gageValues2.getItemAt(sliderValue_2).gageValue + " feet" +
				" and streamgage number " + siteNo_3 + " at " + gageValues3.getItemAt(sliderValue_3).gageValue + " feet</FNT>";
				siteToGage = "<FNT size='7.5'>Map corresponding to selected stages at following sites: " + gageValues.getItemAt(sliderValue).gageValue + " ft at " + siteNo + "; " + gageValues2.getItemAt(sliderValue_2).gageValue + " ft at " + siteNo_2 + "; " + gageValues3.getItemAt(sliderValue_3).gageValue + " ft at " + siteNo_3 + "</FNT>";
			}
			
			printParameters.customParameters.Map_Info = printParameters.customParameters.Map_Info + "|" + siteDefExp + "|" + siteToGage;
			
			/*printParameters.customParameters.Map_Info = siteCommunity + ", " + siteStatePrint + "|" + siteNo + "|" + currentStage + "|" + currentReport + "|"
			+ series_num;
			//+ authors + ", " + rep_date + ", " + title + ": " + rep_series + " " + series_num + ", " + add_info;
			//+ authors + ", " + rep_date + ", " + title + ": " + rep_series + ", " + add_info;*/
			
			if (map.scale < 18000) {
				printParameters.layoutTemplate = "FIMpage2design";
			} else if (map.scale >= 18000 && map.scale < 36000) {
				printParameters.layoutTemplate = "FIMpage2design_18k";
			} else if (map.scale >= 36000 && map.scale < 72000) {
				printParameters.layoutTemplate = "FIMpage2design_36k";
			} else if (map.scale >= 72000 && map.scale < 288000) {
				printParameters.layoutTemplate = "FIMpage2design_72k";
			} else if (map.scale >= 288000) {
				printParameters.layoutTemplate = "FIMpage2design_288k";
			}
			
			//printParameters.layoutTemplate = "FIMpage2design_test";
														
			printParameters.customParameters.rand = Math.floor(Math.random() * (1 + 1000000 - 1)) + 1;
			printParameters.preserveScale = false;
			newPrintTask.requestTimeout = 0;
			
			//newPrintTask.execute(printParameters);
			//printTask.submitJob(printParameters);	
			printTask.submitJob(printParameters);
			printLoadingScreen.visible = true;
			
			//testMap.visible = true;
		} else {
			Alert.show('Currently, the print map function is limited to one request at a time. Thanks for your patience.');
		}
		
		
	}
	
	private function printTask_jobCompleteHandler(event:PrintEvent):void
	{
		var jobInfo:JobInfo = event.jobInfo;
		if (jobInfo.jobStatus == JobInfo.STATUS_SUCCEEDED)
		{
			printTask.getResultData(jobInfo.jobId);
			trace(jobInfo.jobId);
		}
		else
		{
			//Alert.show("print error: " + jobInfo.jobStatus);
			//printLoadingScreen.visible = false;
			printTask.submitJob(printParameters);
			trace('tried again');
		}
	}
	
	private function printTask_getResultDataCompleteHandler(event:PrintEvent):void
	{
		var dataFile:DataFile = event.parameterValue.value as DataFile;
		navigateToURL(new URLRequest(dataFile.url));
		printLoadingScreen.visible = false;
	}
	
	private function printTask_faultHandler(event:FaultEvent):void {
		Alert.show("print error: " + event.message.toString());
		printLoadingScreen.visible = false;
	}
	
	private function printTask_executeCompleteHandler(event:PrintEvent):void
	{
		var paramValue:ParameterValue = event.executeResult.results[0];
		var dataFile:DataFile = paramValue.value as DataFile;
		navigateToURL(new URLRequest(dataFile.url));
		printLoadingScreen.visible = false;
	}

	
	
	



