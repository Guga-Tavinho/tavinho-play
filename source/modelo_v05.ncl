<?xml version="1.0" encoding="UTF-8"?>
<ncl xmlns="http://www.ncl.org.br/NCL3.0/EDTVProfile" id="usbVideoPlayer05">
 <head>
  <regionBase>
   <region id="rVideo" left="0" top="0" width="100%" height="100%" zIndex="1" />
   <region id="rMenu" left="0" top="0" width="100%" height="100%" zIndex="2" />
  </regionBase>
  <descriptorBase>
   <descriptor id="dVideo" region="rVideo">
    <descriptorParam name="fit" value="meet" />
   </descriptor>
   <descriptor id="dMenu" region="rMenu" focusIndex="1" />
  </descriptorBase>
  <connectorBase>
   <causalConnector id="c_start">
    <simpleCondition role="onBegin" />
    <simpleAction role="start" />
   </causalConnector>
   <causalConnector id="c_stop">
    <simpleCondition role="onBegin" />
    <simpleAction role="stop" />
   </causalConnector>
   <causalConnector id="c_pause">
    <simpleCondition role="onBegin" />
    <simpleAction role="pause" />
   </causalConnector>
   <causalConnector id="c_resume">
    <simpleCondition role="onBegin" />
    <simpleAction role="resume" />
   </causalConnector>
   <causalConnector id="c_fim">
    <connectorParam name="valor" />
    <simpleCondition role="onEnd" />
    <simpleAction role="set" value="$valor" />
   </causalConnector>
   <causalConnector id="c_inicio">
    <connectorParam name="valor" />
    <simpleCondition role="onBegin" />
    <simpleAction role="set" value="$valor" />
   </causalConnector>
    <!--RE510_FOCUS_V0610-->
  <causalConnector id="c_usbFocus0610">
   <connectorParam name="valor" />
   <simpleCondition role="onBegin" />
   <simpleAction role="set" value="$valor" />
  </causalConnector>
 </connectorBase>
 </head>
 <body id="playerBody">
  <port id="iniciar" component="controller" />
  <media id="controller" src="player_v05.lua" type="application/x-ginga-NCLua" descriptor="dMenu">
   <property name="estado" />
   <!--USB_AREAS-->
     <area id="usbRetomarControle" label="usbRetomarControle" />
  </media>
  <media id="configuracoes" type="application/x-ginga-settings">
   <property name="service.currentFocus" value="1" />
   <property name="service.currentKeyMaster" value="1" />
   <property name="channel.keyCapture" value="numeric_keys,interactive_keys" />
  </media>
  <!--USB_MEDIA-->
  <!--USB_LINKS-->
   <link id="l_usbFocus0610" xconnector="c_usbFocus0610">
   <linkParam name="valor" value="1" />
   <bind role="onBegin" component="controller" interface="usbRetomarControle" />
   <bind role="set" component="configuracoes" interface="service.currentFocus" />
  </link>
  <link id="l_usbKeyMaster0610" xconnector="c_usbFocus0610">
   <linkParam name="valor" value="1" />
   <bind role="onBegin" component="controller" interface="usbRetomarControle" />
   <bind role="set" component="configuracoes" interface="service.currentKeyMaster" />
  </link>
 </body>
</ncl>
