# Xournalpp - PDF annotation and note-taking
{ pkgs, ... }:

{
  # Xournalpp is already in home.packages
  # This module adds configuration

  xdg.configFile."xournalpp/settings.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <settings>
      <!-- Window Configuration -->
      <property name="maximized" value="true"/>
      <property name="windowWidth" value="1920"/>
      <property name="windowHeight" value="1080"/>

      <!-- Interface -->
      <property name="darkTheme" value="true"/>
      <property name="showSidebar" value="true"/>
      <property name="sidebarWidth" value="150"/>
      <property name="showToolbar" value="true"/>
      <property name="showMenubar" value="true"/>

      <!-- Input Settings -->
      <property name="presureSensitivity" value="true"/>
      <property name="minimumPressure" value="0.05"/>
      <property name="pressureMultiplier" value="1.0"/>
      <property name="stylusCursorType" value="dot"/>
      <property name="eraserVisibility" value="always"/>
      <property name="touchDrawing" value="false"/>
      <property name="gtkTouchInertialScrolling" value="true"/>

      <!-- Stroke Stabilization -->
      <property name="strokeFilterEnabled" value="true"/>
      <property name="strokeFilterBuffersize" value="20"/>
      <property name="strokeFilterSigma" value="0.5"/>

      <!-- Default Tools -->
      <property name="selectedToolbar" value="Text"/>
      <property name="penColor" value="0x3333cc"/>
      <property name="penSize" value="MEDIUM"/>
      <property name="highlighterColor" value="0xffff00"/>
      <property name="highlighterOpacity" value="128"/>
      <property name="eraserSize" value="MEDIUM"/>

      <!-- Auto-save -->
      <property name="autosaveEnabled" value="true"/>
      <property name="autosaveTimeout" value="3"/>
      <property name="defaultSaveName" value="%F-Note-%H-%M"/>

      <!-- Grid & Snapping -->
      <property name="snapGrid" value="true"/>
      <property name="snapGridSize" value="14.17"/>
      <property name="snapGridTolerance" value="0.5"/>
      <property name="snapRotation" value="true"/>
      <property name="snapRotationTolerance" value="0.3"/>

      <!-- LaTeX -->
      <property name="latexAutoCheckDependencies" value="true"/>

      <!-- Display -->
      <property name="displayDpi" value="72"/>
    </settings>
  '';
}
