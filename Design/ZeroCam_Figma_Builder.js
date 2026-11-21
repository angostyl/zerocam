// ZeroCam iOS - Script Gerador para Figma Plugin API
// Cria um conceito de 4 ecrãs de alta fidelidade para o ZeroCam iOS no Figma.

(async function createZeroCamConcept() {
  // 1. Carregar tipografias necessárias
  await figma.loadFontAsync({ family: "Inter", style: "Regular" });
  await figma.loadFontAsync({ family: "Inter", style: "Medium" });
  await figma.loadFontAsync({ family: "Inter", style: "Semi Bold" });
  await figma.loadFontAsync({ family: "Inter", style: "Bold" });

  const cYellow = { r: 0.98, g: 0.77, b: 0.1 };       // #F9C51A (Kodak Gold)
  const cBlack = { r: 0.05, g: 0.05, b: 0.06 };        // #0D0D0F (Deep Obsidian)
  const cDark = { r: 0.1, g: 0.1, b: 0.12 };          // #1A1A1E (Surface)
  const cSurfaceHover = { r: 0.16, g: 0.16, b: 0.18 };// #29292E
  const cWhite = { r: 1, g: 1, b: 1 };
  const cMuted = { r: 0.55, g: 0.55, b: 0.6 };

  function solid(color, opacity = 1) {
    return [{ type: 'SOLID', color, opacity }];
  }

  // Canvas Wrapper Principal (Artboard de Apresentação)
  const board = figma.createFrame();
  board.name = "ZeroCam iOS — Design Concept & Architecture";
  board.resize(1840, 1160);
  board.fills = solid({ r: 0.07, g: 0.07, b: 0.08 });
  board.cornerRadius = 24;
  board.x = 0;
  board.y = 0;

  // Header do Projecto
  const header = figma.createFrame();
  header.name = "Header Banner";
  header.resize(1720, 140);
  header.x = 60;
  header.y = 40;
  header.fills = solid(cDark, 0.7);
  header.cornerRadius = 18;
  header.strokes = solid(cWhite, 0.08);
  header.strokeWeight = 1;
  header.layoutMode = "VERTICAL";
  header.paddingLeft = 32;
  header.paddingRight = 32;
  header.paddingTop = 24;
  header.paddingBottom = 24;
  header.itemSpacing = 8;
  board.appendChild(header);

  const tagText = figma.createText();
  tagText.fontName = { family: "Inter", style: "Bold" };
  tagText.fontSize = 12;
  tagText.characters = "IOS NATIVE ARCHITECTURE • ZERO COMPUTATIONAL ENGINE • 14-BIT BAYER RAW";
  tagText.fills = solid(cYellow);
  header.appendChild(tagText);

  const titleText = figma.createText();
  titleText.fontName = { family: "Inter", style: "Bold" };
  titleText.fontSize = 28;
  titleText.characters = "ZeroCam — Pure Optical Film Camera (Conceito iOS)";
  titleText.fills = solid(cWhite);
  header.appendChild(titleText);

  const subText = figma.createText();
  subText.fontName = { family: "Inter", style: "Regular" };
  subText.fontSize = 14;
  subText.characters = "Captura ótica monocadência pura sem Smart HDR da Apple • Simulações densitométricas analógicas (Portra 400, Classic Chrome, Tri-X 400)";
  subText.fills = solid(cMuted);
  header.appendChild(subText);

  // Função auxiliar para criar iPhone Frame (393 x 852 - iPhone 16 Pro)
  function createPhoneScreen(name, x, y) {
    const phone = figma.createFrame();
    phone.name = name;
    phone.resize(393, 852);
    phone.x = x;
    phone.y = y;
    phone.fills = solid(cBlack);
    phone.cornerRadius = 48;
    phone.strokes = solid(cWhite, 0.15);
    phone.strokeWeight = 2;
    phone.clipsContent = true;

    // Dynamic Island
    const island = figma.createFrame();
    island.name = "Dynamic Island";
    island.resize(124, 34);
    island.x = (393 - 124) / 2;
    island.y = 12;
    island.fills = solid({ r: 0, g: 0, b: 0 });
    island.cornerRadius = 17;
    island.strokes = solid(cWhite, 0.05);
    island.strokeWeight = 1;
    phone.appendChild(island);

    // Status Bar - Relógio e Sinais
    const timeText = figma.createText();
    timeText.fontName = { family: "Inter", style: "Semi Bold" };
    timeText.fontSize = 14;
    timeText.characters = "9:41";
    timeText.fills = solid(cWhite);
    timeText.x = 34;
    timeText.y = 18;
    phone.appendChild(timeText);

    const iconsText = figma.createText();
    iconsText.fontName = { family: "Inter", style: "Semi Bold" };
    iconsText.fontSize = 12;
    iconsText.characters = "5G  100%";
    iconsText.fills = solid(cWhite, 0.85);
    iconsText.x = 310;
    iconsText.y = 20;
    phone.appendChild(iconsText);

    return phone;
  }

  // ==========================================
  // ECRÃ 1: Auto EV Mode (Viewfinder 3:4)
  // ==========================================
  const screen1 = createPhoneScreen("01 · Auto EV Viewfinder", 60, 220);
  board.appendChild(screen1);

  // Top Bar Screen 1
  const topBar1 = figma.createFrame();
  topBar1.name = "Top Bar";
  topBar1.resize(353, 44);
  topBar1.x = 20;
  topBar1.y = 56;
  topBar1.fills = [];
  topBar1.layoutMode = "HORIZONTAL";
  topBar1.primaryAxisAlignItems = "SPACE_BETWEEN";
  topBar1.counterAxisAlignItems = "CENTER";
  screen1.appendChild(topBar1);

  // Recipe Badge Pill
  const recipeBadge = figma.createFrame();
  recipeBadge.resize(110, 32);
  recipeBadge.fills = solid(cWhite, 0.12);
  recipeBadge.cornerRadius = 16;
  recipeBadge.layoutMode = "HORIZONTAL";
  recipeBadge.counterAxisAlignItems = "CENTER";
  recipeBadge.paddingLeft = 10;
  recipeBadge.itemSpacing = 6;
  const dot = figma.createEllipse();
  dot.resize(6, 6);
  dot.fills = solid(cYellow);
  recipeBadge.appendChild(dot);
  const recText = figma.createText();
  recText.fontName = { family: "Inter", style: "Bold" };
  recText.fontSize = 11;
  recText.characters = "PORTRA 400";
  recText.fills = solid(cWhite);
  recipeBadge.appendChild(recText);
  topBar1.appendChild(recipeBadge);

  // Auto / Pro Toggle
  const modePill = figma.createFrame();
  modePill.resize(100, 32);
  modePill.fills = solid(cWhite, 0.08);
  modePill.cornerRadius = 16;
  modePill.layoutMode = "HORIZONTAL";
  modePill.paddingLeft = 3;
  modePill.paddingRight = 3;
  modePill.paddingTop = 3;
  modePill.paddingBottom = 3;
  modePill.itemSpacing = 2;

  const autoBtn = figma.createFrame();
  autoBtn.resize(46, 26);
  autoBtn.fills = solid(cYellow);
  autoBtn.cornerRadius = 13;
  const aText = figma.createText();
  aText.fontName = { family: "Inter", style: "Bold" };
  aText.fontSize = 10;
  aText.characters = "AUTO";
  aText.fills = solid(cBlack);
  aText.x = 9; aText.y = 7;
  autoBtn.appendChild(aText);
  modePill.appendChild(autoBtn);

  const proBtn = figma.createFrame();
  proBtn.resize(46, 26);
  proBtn.fills = [];
  const pText = figma.createText();
  pText.fontName = { family: "Inter", style: "Bold" };
  pText.fontSize = 10;
  pText.characters = "PRO";
  pText.fills = solid(cWhite, 0.6);
  pText.x = 12; pText.y = 7;
  proBtn.appendChild(pText);
  modePill.appendChild(proBtn);
  topBar1.appendChild(modePill);

  // Viewfinder 3:4 Frame
  const viewfinder = figma.createFrame();
  viewfinder.name = "Viewfinder (3:4 Sensor)";
  viewfinder.resize(361, 481);
  viewfinder.x = 16;
  viewfinder.y = 112;
  viewfinder.fills = solid({ r: 0.14, g: 0.15, b: 0.17 });
  viewfinder.cornerRadius = 18;
  viewfinder.strokes = solid(cWhite, 0.15);
  viewfinder.strokeWeight = 1;
  viewfinder.clipsContent = true;
  screen1.appendChild(viewfinder);

  // Rule of thirds lines
  for (let i = 1; i <= 2; i++) {
    const vLine = figma.createLine();
    vLine.resize(481, 0);
    vLine.rotation = 90;
    vLine.x = (361 / 3) * i;
    vLine.y = 0;
    vLine.strokes = solid(cWhite, 0.12);
    viewfinder.appendChild(vLine);

    const hLine = figma.createLine();
    hLine.resize(361, 0);
    hLine.x = 0;
    hLine.y = (481 / 3) * i;
    hLine.strokes = solid(cWhite, 0.12);
    viewfinder.appendChild(hLine);
  }

  // Foco Retículo Central
  const reticle = figma.createFrame();
  reticle.name = "Focus Reticle";
  reticle.resize(60, 60);
  reticle.x = 150;
  reticle.y = 180;
  reticle.fills = [];
  reticle.strokes = solid(cYellow);
  reticle.strokeWeight = 1.5;
  const centerDot = figma.createEllipse();
  centerDot.resize(4, 4);
  centerDot.x = 28; centerDot.y = 28;
  centerDot.fills = solid(cYellow);
  reticle.appendChild(centerDot);
  viewfinder.appendChild(reticle);

  // Lens Switcher Capsule
  const lensBar = figma.createFrame();
  lensBar.name = "Lens Switcher";
  lensBar.resize(200, 36);
  lensBar.x = 80;
  lensBar.y = 430;
  lensBar.fills = solid(cBlack, 0.65);
  lensBar.cornerRadius = 18;
  lensBar.strokes = solid(cWhite, 0.15);
  lensBar.strokeWeight = 1;
  lensBar.layoutMode = "HORIZONTAL";
  lensBar.paddingLeft = 4;
  lensBar.itemSpacing = 4;
  lensBar.counterAxisAlignItems = "CENTER";
  ['0.5x', '1x', '2x', '5x'].forEach((lens, idx) => {
    const lPill = figma.createFrame();
    lPill.resize(44, 28);
    lPill.cornerRadius = 14;
    lPill.fills = idx === 1 ? solid(cYellow) : solid(cBlack, 0.3);
    const lTxt = figma.createText();
    lTxt.fontName = { family: "Inter", style: "Bold" };
    lTxt.fontSize = 11;
    lTxt.characters = lens;
    lTxt.fills = idx === 1 ? solid(cBlack) : solid(cWhite);
    lTxt.x = 10; lTxt.y = 7;
    lPill.appendChild(lTxt);
    lensBar.appendChild(lPill);
  });
  viewfinder.appendChild(lensBar);

  // Auto EV Slider Bar
  const evBar = figma.createFrame();
  evBar.name = "EV Bar";
  evBar.resize(361, 44);
  evBar.x = 16;
  evBar.y = 610;
  evBar.fills = solid(cWhite, 0.04);
  evBar.cornerRadius = 12;
  evBar.layoutMode = "HORIZONTAL";
  evBar.counterAxisAlignItems = "CENTER";
  evBar.primaryAxisAlignItems = "SPACE_BETWEEN";
  evBar.paddingLeft = 16;
  evBar.paddingRight = 16;
  screen1.appendChild(evBar);

  const evLabel = figma.createText();
  evLabel.fontName = { family: "Inter", style: "Bold" };
  evLabel.fontSize = 12;
  evLabel.characters = "EV";
  evLabel.fills = solid(cMuted);
  evBar.appendChild(evLabel);

  const sliderLine = figma.createFrame();
  sliderLine.resize(230, 4);
  sliderLine.cornerRadius = 2;
  sliderLine.fills = solid(cWhite, 0.2);
  const activeEv = figma.createEllipse();
  activeEv.resize(14, 14);
  activeEv.x = 135; activeEv.y = -5;
  activeEv.fills = solid(cYellow);
  sliderLine.appendChild(activeEv);
  evBar.appendChild(sliderLine);

  const evVal = figma.createText();
  evVal.fontName = { family: "Inter", style: "Bold" };
  evVal.fontSize = 12;
  evVal.characters = "+0.3";
  evVal.fills = solid(cYellow);
  evBar.appendChild(evVal);

  // Bottom Control Bar (Shutter, Gallery, Raw Badge)
  const botBar = figma.createFrame();
  botBar.name = "Bottom Shutter Bar";
  botBar.resize(361, 90);
  botBar.x = 16;
  botBar.y = 674;
  botBar.fills = [];
  botBar.layoutMode = "HORIZONTAL";
  botBar.counterAxisAlignItems = "CENTER";
  botBar.primaryAxisAlignItems = "SPACE_BETWEEN";
  screen1.appendChild(botBar);

  // Miniatura Galeria
  const thumb = figma.createFrame();
  thumb.resize(54, 54);
  thumb.cornerRadius = 12;
  thumb.fills = solid({ r: 0.2, g: 0.22, b: 0.25 });
  thumb.strokes = solid(cWhite, 0.3);
  thumb.strokeWeight = 1.5;
  const rawTag = figma.createText();
  rawTag.fontName = { family: "Inter", style: "Bold" };
  rawTag.fontSize = 8;
  rawTag.characters = "RAW";
  rawTag.fills = solid(cYellow);
  rawTag.x = 14; rawTag.y = 36;
  thumb.appendChild(rawTag);
  botBar.appendChild(thumb);

  // Botão Obturador
  const shutter = figma.createFrame();
  shutter.name = "Mechanical Shutter Button";
  shutter.resize(76, 76);
  shutter.cornerRadius = 38;
  shutter.fills = [];
  shutter.strokes = solid(cWhite);
  shutter.strokeWeight = 3.5;
  const innerShutter = figma.createEllipse();
  innerShutter.resize(62, 62);
  innerShutter.x = 7; innerShutter.y = 7;
  innerShutter.fills = solid(cWhite);
  shutter.appendChild(innerShutter);
  botBar.appendChild(shutter);

  // Badge Status
  const statusBadge = figma.createFrame();
  statusBadge.resize(60, 40);
  statusBadge.fills = [];
  statusBadge.layoutMode = "VERTICAL";
  statusBadge.counterAxisAlignItems = "CENTER";
  const st1 = figma.createText();
  st1.fontName = { family: "Inter", style: "Bold" };
  st1.fontSize = 10;
  st1.characters = "PORTRA";
  st1.fills = solid(cYellow);
  statusBadge.appendChild(st1);
  const st2 = figma.createText();
  st2.fontName = { family: "Inter", style: "Bold" };
  st2.fontSize = 8;
  st2.characters = "14-BIT RAW";
  st2.fills = solid(cMuted);
  statusBadge.appendChild(st2);
  botBar.appendChild(statusBadge);

  // ==========================================
  // ECRÃ 2: Pro Manual Mode (ISO/Shutter/Focus/WB)
  // ==========================================
  const screen2 = createPhoneScreen("02 · Pro Manual Controls", 493, 220);
  board.appendChild(screen2);

  // Top Bar Screen 2 (com PRO activo)
  const topBar2 = figma.createFrame();
  topBar2.resize(353, 44);
  topBar2.x = 20; topBar2.y = 56;
  topBar2.fills = [];
  topBar2.layoutMode = "HORIZONTAL";
  topBar2.primaryAxisAlignItems = "SPACE_BETWEEN";
  topBar2.counterAxisAlignItems = "CENTER";
  screen2.appendChild(topBar2);

  const recipeBadge2 = figma.createFrame();
  recipeBadge2.resize(110, 32);
  recipeBadge2.fills = solid(cWhite, 0.12);
  recipeBadge2.cornerRadius = 16;
  recipeBadge2.layoutMode = "HORIZONTAL";
  recipeBadge2.counterAxisAlignItems = "CENTER";
  recipeBadge2.paddingLeft = 10;
  recipeBadge2.itemSpacing = 6;
  const dot2 = figma.createEllipse();
  dot2.resize(6, 6);
  dot2.fills = solid(cYellow);
  recipeBadge2.appendChild(dot2);
  const recText2 = figma.createText();
  recText2.fontName = { family: "Inter", style: "Bold" };
  recText2.fontSize = 11;
  recText2.characters = "CHROME";
  recText2.fills = solid(cWhite);
  recipeBadge2.appendChild(recText2);
  topBar2.appendChild(recipeBadge2);

  const modePill2 = figma.createFrame();
  modePill2.resize(100, 32);
  modePill2.fills = solid(cWhite, 0.08);
  modePill2.cornerRadius = 16;
  modePill2.layoutMode = "HORIZONTAL";
  modePill2.paddingLeft = 3;
  modePill2.itemSpacing = 2;

  const autoBtn2 = figma.createFrame();
  autoBtn2.resize(46, 26);
  autoBtn2.fills = [];
  const aText2 = figma.createText();
  aText2.fontName = { family: "Inter", style: "Bold" };
  aText2.fontSize = 10;
  aText2.characters = "AUTO";
  aText2.fills = solid(cWhite, 0.6);
  aText2.x = 9; aText2.y = 7;
  autoBtn2.appendChild(aText2);
  modePill2.appendChild(autoBtn2);

  const proBtn2 = figma.createFrame();
  proBtn2.resize(46, 26);
  proBtn2.fills = solid(cYellow);
  proBtn2.cornerRadius = 13;
  const pText2 = figma.createText();
  pText2.fontName = { family: "Inter", style: "Bold" };
  pText2.fontSize = 10;
  pText2.characters = "PRO";
  pText2.fills = solid(cBlack);
  pText2.x = 12; pText2.y = 7;
  proBtn2.appendChild(pText2);
  modePill2.appendChild(proBtn2);
  topBar2.appendChild(modePill2);

  // Viewfinder Screen 2 (ligeiramente mais compacto para acomodar drawer manual)
  const vf2 = figma.createFrame();
  vf2.resize(361, 410);
  vf2.x = 16; vf2.y = 112;
  vf2.fills = solid({ r: 0.12, g: 0.14, b: 0.16 });
  vf2.cornerRadius = 18;
  vf2.strokes = solid(cWhite, 0.15);
  vf2.strokeWeight = 1;
  vf2.clipsContent = true;
  screen2.appendChild(vf2);

  // Histograma de Exposição no topo do Viewfinder
  const hist = figma.createFrame();
  hist.name = "Exposure Histogram";
  hist.resize(80, 36);
  hist.x = 16; hist.y = 16;
  hist.fills = solid(cBlack, 0.6);
  hist.cornerRadius = 6;
  hist.strokes = solid(cWhite, 0.15);
  hist.strokeWeight = 1;
  const histText = figma.createText();
  histText.fontName = { family: "Inter", style: "Bold" };
  histText.fontSize = 9;
  histText.characters = "14-BIT HIST";
  histText.fills = solid(cYellow);
  histText.x = 8; histText.y = 12;
  hist.appendChild(histText);
  vf2.appendChild(hist);

  // Gaveta PRO Manual
  const proDrawer = figma.createFrame();
  proDrawer.name = "Pro Manual Controls Drawer";
  proDrawer.resize(361, 140);
  proDrawer.x = 16;
  proDrawer.y = 534;
  proDrawer.fills = solid(cWhite, 0.06);
  proDrawer.cornerRadius = 16;
  proDrawer.strokes = solid(cWhite, 0.1);
  proDrawer.strokeWeight = 1;
  proDrawer.layoutMode = "VERTICAL";
  proDrawer.paddingLeft = 14;
  proDrawer.paddingRight = 14;
  proDrawer.paddingTop = 12;
  proDrawer.paddingBottom = 12;
  proDrawer.itemSpacing = 12;
  screen2.appendChild(proDrawer);

  // Tab Buttons (ISO, OBT, FOCO, WB)
  const tabRow = figma.createFrame();
  tabRow.resize(333, 32);
  tabRow.fills = [];
  tabRow.layoutMode = "HORIZONTAL";
  tabRow.itemSpacing = 8;
  ['ISO', 'OBT', 'FOCO', 'WB'].forEach((tab, idx) => {
    const tabPill = figma.createFrame();
    tabPill.resize(77, 30);
    tabPill.cornerRadius = 8;
    tabPill.fills = idx === 0 ? solid(cYellow) : solid(cWhite, 0.08);
    const tTxt = figma.createText();
    tTxt.fontName = { family: "Inter", style: "Bold" };
    tTxt.fontSize = 11;
    tTxt.characters = tab;
    tTxt.fills = idx === 0 ? solid(cBlack) : solid(cWhite, 0.7);
    tTxt.x = 24; tTxt.y = 8;
    tabPill.appendChild(tTxt);
    tabRow.appendChild(tabPill);
  });
  proDrawer.appendChild(tabRow);

  // Valor ISO e Dial Graduado
  const dialRow = figma.createFrame();
  dialRow.resize(333, 44);
  dialRow.fills = [];
  dialRow.layoutMode = "HORIZONTAL";
  dialRow.counterAxisAlignItems = "CENTER";
  dialRow.primaryAxisAlignItems = "SPACE_BETWEEN";

  const isoReadout = figma.createText();
  isoReadout.fontName = { family: "Inter", style: "Bold" };
  isoReadout.fontSize = 20;
  isoReadout.characters = "ISO 160";
  isoReadout.fills = solid(cYellow);
  dialRow.appendChild(isoReadout);

  const dialTicks = figma.createText();
  dialTicks.fontName = { family: "Inter", style: "Regular" };
  dialTicks.fontSize = 11;
  dialTicks.characters = "50 · 100 · [160] · 200 · 400 · 800";
  dialTicks.fills = solid(cMuted);
  dialRow.appendChild(dialTicks);
  proDrawer.appendChild(dialRow);

  // Telemetria Secundária
  const teleText = figma.createText();
  teleText.fontName = { family: "Inter", style: "Medium" };
  teleText.fontSize = 11;
  teleText.characters = "1/500s  •  f/1.78  •  24mm  •  5500K";
  teleText.fills = solid(cWhite, 0.8);
  proDrawer.appendChild(teleText);

  // Bottom Bar Screen 2
  const botBar2 = figma.createFrame();
  botBar2.resize(361, 90);
  botBar2.x = 16; botBar2.y = 684;
  botBar2.fills = [];
  botBar2.layoutMode = "HORIZONTAL";
  botBar2.counterAxisAlignItems = "CENTER";
  botBar2.primaryAxisAlignItems = "SPACE_BETWEEN";
  screen2.appendChild(botBar2);

  const thumb2 = figma.createFrame();
  thumb2.resize(54, 54);
  thumb2.cornerRadius = 12;
  thumb2.fills = solid({ r: 0.18, g: 0.2, b: 0.22 });
  thumb2.strokes = solid(cWhite, 0.3);
  thumb2.strokeWeight = 1.5;
  botBar2.appendChild(thumb2);

  const shutter2 = figma.createFrame();
  shutter2.resize(76, 76);
  shutter2.cornerRadius = 38;
  shutter2.fills = [];
  shutter2.strokes = solid(cWhite);
  shutter2.strokeWeight = 3.5;
  const inShutter2 = figma.createEllipse();
  inShutter2.resize(62, 62);
  inShutter2.x = 7; inShutter2.y = 7;
  inShutter2.fills = solid(cWhite);
  shutter2.appendChild(inShutter2);
  botBar2.appendChild(shutter2);

  const stBadge2 = figma.createFrame();
  stBadge2.resize(60, 40);
  stBadge2.fills = [];
  stBadge2.layoutMode = "VERTICAL";
  stBadge2.counterAxisAlignItems = "CENTER";
  const st2_1 = figma.createText();
  st2_1.fontName = { family: "Inter", style: "Bold" };
  st2_1.fontSize = 10;
  st2_1.characters = "MANUAL";
  st2_1.fills = solid(cYellow);
  stBadge2.appendChild(st2_1);
  const st2_2 = figma.createText();
  st2_2.fontName = { family: "Inter", style: "Bold" };
  st2_2.fontSize = 8;
  st2_2.characters = "LOCK";
  st2_2.fills = solid(cMuted);
  stBadge2.appendChild(st2_2);
  botBar2.appendChild(stBadge2);

  // ==========================================
  // ECRÃ 3: Film Simulation Recipe Drawer
  // ==========================================
  const screen3 = createPhoneScreen("03 · Film Recipes Drawer", 926, 220);
  board.appendChild(screen3);

  // Fundo com desfoque e Viewfinder escurecido
  const bgDim = figma.createFrame();
  bgDim.resize(393, 852);
  bgDim.fills = solid(cBlack, 0.85);
  screen3.appendChild(bgDim);

  // Drawer Sheet
  const sheet = figma.createFrame();
  sheet.name = "Recipes Bottom Sheet";
  sheet.resize(393, 620);
  sheet.x = 0; sheet.y = 232;
  sheet.fills = solid(cDark);
  sheet.cornerRadius = 32;
  sheet.strokes = solid(cWhite, 0.12);
  sheet.strokeWeight = 1;
  sheet.layoutMode = "VERTICAL";
  sheet.paddingLeft = 20;
  sheet.paddingRight = 20;
  sheet.paddingTop = 12;
  sheet.paddingBottom = 24;
  sheet.itemSpacing = 16;
  screen3.appendChild(sheet);

  // Handle bar
  const handle = figma.createFrame();
  handle.resize(40, 4);
  handle.cornerRadius = 2;
  handle.fills = solid(cWhite, 0.3);
  sheet.appendChild(handle);

  // Sheet Header
  const sHead = figma.createFrame();
  sHead.resize(353, 40);
  sHead.fills = [];
  sHead.layoutMode = "VERTICAL";
  const sTitle = figma.createText();
  sTitle.fontName = { family: "Inter", style: "Bold" };
  sTitle.fontSize = 18;
  sTitle.characters = "Emulsões & Receitas de Filme";
  sTitle.fills = solid(cWhite);
  sHead.appendChild(sTitle);

  const sSub = figma.createText();
  sSub.fontName = { family: "Inter", style: "Regular" };
  sSub.fontSize = 11;
  sSub.characters = "Curvas químicas reais sem tone-mapping digital artificial";
  sSub.fills = solid(cMuted);
  sHead.appendChild(sSub);
  sheet.appendChild(sHead);

  // Lista de Receitas de Filme
  const recipes = [
    { name: "Kodak Portra 400", desc: "Tons de pele quentes, sombras suaves e saturação natural.", tag: "COLOR", active: true },
    { name: "Fujifilm Classic Chrome", desc: "Saturação contida (-22%) e contraste dramático de sombras.", tag: "COLOR", active: false },
    { name: "Kodak Tri-X 400", desc: "Preto e branco clássico de alto contraste com grão argêntico.", tag: "B&W", active: false },
    { name: "Process Zero (Bayer RAW)", desc: "Ótica mono-frame pura sem qualquer interpolação.", tag: "RAW", active: false }
  ];

  recipes.forEach(r => {
    const card = figma.createFrame();
    card.name = `Card: ${r.name}`;
    card.resize(353, 86);
    card.cornerRadius = 14;
    card.fills = r.active ? solid(cSurfaceHover) : solid(cWhite, 0.04);
    card.strokes = r.active ? solid(cYellow, 0.6) : solid(cWhite, 0.08);
    card.strokeWeight = 1;
    card.layoutMode = "HORIZONTAL";
    card.counterAxisAlignItems = "CENTER";
    card.paddingLeft = 14;
    card.paddingRight = 14;
    card.itemSpacing = 12;

    const sample = figma.createFrame();
    sample.resize(56, 56);
    sample.cornerRadius = 8;
    sample.fills = r.active ? solid(cYellow, 0.3) : solid(cWhite, 0.1);
    const sampleText = figma.createText();
    sampleText.fontName = { family: "Inter", style: "Bold" };
    sampleText.fontSize = 10;
    sampleText.characters = r.tag;
    sampleText.fills = r.active ? solid(cYellow) : solid(cWhite, 0.6);
    sampleText.x = 10; sampleText.y = 22;
    sample.appendChild(sampleText);
    card.appendChild(sample);

    const info = figma.createFrame();
    info.resize(230, 56);
    info.fills = [];
    info.layoutMode = "VERTICAL";
    info.itemSpacing = 4;

    const rName = figma.createText();
    rName.fontName = { family: "Inter", style: "Bold" };
    rName.fontSize = 14;
    rName.characters = r.name;
    rName.fills = r.active ? solid(cYellow) : solid(cWhite);
    info.appendChild(rName);

    const rDesc = figma.createText();
    rDesc.fontName = { family: "Inter", style: "Regular" };
    rDesc.fontSize = 10;
    rDesc.characters = r.desc;
    rDesc.fills = solid(cMuted);
    info.appendChild(rDesc);
    card.appendChild(info);

    sheet.appendChild(card);
  });

  // ==========================================
  // ECRÃ 4: Darkroom & RAW Inspector
  // ==========================================
  const screen4 = createPhoneScreen("04 · Darkroom & RAW Inspector", 1359, 220);
  board.appendChild(screen4);

  // Top Bar Gallery
  const gTop = figma.createFrame();
  gTop.resize(353, 44);
  gTop.x = 20; gTop.y = 56;
  gTop.fills = [];
  gTop.layoutMode = "HORIZONTAL";
  gTop.primaryAxisAlignItems = "SPACE_BETWEEN";
  gTop.counterAxisAlignItems = "CENTER";
  screen4.appendChild(gTop);

  const backBtn = figma.createText();
  backBtn.fontName = { family: "Inter", style: "Semi Bold" };
  backBtn.fontSize = 14;
  backBtn.characters = "‹ Câmara";
  backBtn.fills = solid(cYellow);
  gTop.appendChild(backBtn);

  const rawBadge = figma.createFrame();
  rawBadge.resize(80, 26);
  rawBadge.cornerRadius = 6;
  rawBadge.fills = solid(cWhite, 0.1);
  const rawTitle = figma.createText();
  rawTitle.fontName = { family: "Inter", style: "Bold" };
  rawTitle.fontSize = 10;
  rawTitle.characters = "14-BIT DNG";
  rawTitle.fills = solid(cWhite);
  rawTitle.x = 10; rawTitle.y = 6;
  rawBadge.appendChild(rawTitle);
  gTop.appendChild(rawBadge);

  // Moldura Fotográfica com Rebordo de Película (Film Border)
  const filmFrame = figma.createFrame();
  filmFrame.name = "Film Contact Frame";
  filmFrame.resize(361, 450);
  filmFrame.x = 16; filmFrame.y = 112;
  filmFrame.fills = solid({ r: 0.08, g: 0.08, b: 0.09 });
  filmFrame.cornerRadius = 12;
  filmFrame.strokes = solid(cWhite, 0.2);
  filmFrame.strokeWeight = 1;
  filmFrame.clipsContent = true;
  screen4.appendChild(filmFrame);

  // Borda superior da película
  const rebateTop = figma.createFrame();
  rebateTop.resize(361, 24);
  rebateTop.fills = solid({ r: 0.04, g: 0.04, b: 0.05 });
  const filmCode = figma.createText();
  filmCode.fontName = { family: "Inter", style: "Bold" };
  filmCode.fontSize = 9;
  filmCode.characters = "● KODAK PORTRA 400 • FRAME 24A • EXP 14-BIT RAW";
  filmCode.fills = solid(cYellow, 0.85);
  filmCode.x = 14; filmCode.y = 6;
  rebateTop.appendChild(filmCode);
  filmFrame.appendChild(rebateTop);

  // Espaço da Imagem Revelada
  const photoCanvas = figma.createFrame();
  photoCanvas.resize(361, 402);
  photoCanvas.y = 24;
  photoCanvas.fills = solid({ r: 0.16, g: 0.17, b: 0.19 });
  filmFrame.appendChild(photoCanvas);

  // Drawer de Metadados EXIF
  const exifBox = figma.createFrame();
  exifBox.name = "EXIF Metadata Inspector";
  exifBox.resize(361, 160);
  exifBox.x = 16; exifBox.y = 576;
  exifBox.fills = solid(cWhite, 0.05);
  exifBox.cornerRadius = 16;
  exifBox.strokes = solid(cWhite, 0.08);
  exifBox.strokeWeight = 1;
  exifBox.layoutMode = "VERTICAL";
  exifBox.paddingLeft = 16;
  exifBox.paddingRight = 16;
  exifBox.paddingTop = 14;
  exifBox.paddingBottom = 14;
  exifBox.itemSpacing = 8;
  screen4.appendChild(exifBox);

  const exifT = figma.createText();
  exifT.fontName = { family: "Inter", style: "Bold" };
  exifT.fontSize = 12;
  exifT.characters = "METADADOS DE CAPTURA ÓTICA";
  exifT.fills = solid(cYellow);
  exifBox.appendChild(exifT);

  const specs = [
    "Ficheiro: Adobe DNG Bayer RAW (14-bit mono-frame)",
    "Resolução: 48 Megapixels (8064 × 6048 px)",
    "Parâmetros: 24mm f/1.78 • 1/500s • ISO 160 • +0.3 EV",
    "Processamento Apple: Smart HDR DESLIGADO • Deep Fusion DESLIGADO"
  ];

  specs.forEach(s => {
    const l = figma.createText();
    l.fontName = { family: "Inter", style: "Regular" };
    l.fontSize = 10;
    l.characters = s;
    l.fills = solid(cWhite, 0.75);
    exifBox.appendChild(l);
  });

  // Botão Exportar DNG Puro
  const exportBtn = figma.createFrame();
  exportBtn.resize(361, 48);
  exportBtn.x = 16; exportBtn.y = 750;
  exportBtn.cornerRadius = 24;
  exportBtn.fills = solid(cYellow);
  exportBtn.layoutMode = "HORIZONTAL";
  exportBtn.counterAxisAlignItems = "CENTER";
  exportBtn.primaryAxisAlignItems = "CENTER";
  const expTxt = figma.createText();
  expTxt.fontName = { family: "Inter", style: "Bold" };
  expTxt.fontSize = 13;
  expTxt.characters = "Revelar no Motor Analógico (PC)";
  expTxt.fills = solid(cBlack);
  exportBtn.appendChild(expTxt);
  screen4.appendChild(exportBtn);

  // Foco do Figma no novo conceito
  figma.viewport.scrollAndZoomIntoView([board]);

  return {
    success: true,
    message: "Conceito ZeroCam iOS criado com sucesso no Figma!",
    boardId: board.id,
    screenIds: [screen1.id, screen2.id, screen3.id, screen4.id]
  };
})();
