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
   <area id="abrir_v0001" label="abrir_v0001"/>
<area id="parar_v0001" label="parar_v0001"/>
<area id="pausar_v0001" label="pausar_v0001"/>
<area id="continuar_v0001" label="continuar_v0001"/>
     <area id="usbRetomarControle" label="usbRetomarControle" />
  </media>
  <media id="configuracoes" type="application/x-ginga-settings">
   <property name="service.currentFocus" value="1" />
   <property name="service.currentKeyMaster" value="1" />
   <property name="channel.keyCapture" value="numeric_keys,interactive_keys" />
  </media>
  <media id="v0001" src="../../../Videos/Exemplo-Tavinho-Play.mp4" type="video/mp4" descriptor="dVideo"/>
  <link id="l_abrir_v0001" xconnector="c_start"><bind role="onBegin" component="controller" interface="abrir_v0001"/><bind role="start" component="v0001"/></link>
<link id="l_parar_v0001" xconnector="c_stop"><bind role="onBegin" component="controller" interface="parar_v0001"/><bind role="stop" component="v0001"/></link>
<link id="l_pausar_v0001" xconnector="c_pause"><bind role="onBegin" component="controller" interface="pausar_v0001"/><bind role="pause" component="v0001"/></link>
<link id="l_continuar_v0001" xconnector="c_resume"><bind role="onBegin" component="controller" interface="continuar_v0001"/><bind role="resume" component="v0001"/></link>
<link id="l_tocando_v0001" xconnector="c_inicio"><linkParam name="valor" value="tocando:v0001"/><bind role="onBegin" component="v0001"/><bind role="set" component="controller" interface="estado"/></link>
<link id="l_fim_v0001" xconnector="c_fim"><linkParam name="valor" value="fim:v0001"/><bind role="onEnd" component="v0001"/><bind role="set" component="controller" interface="estado"/></link>
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
