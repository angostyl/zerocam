// ZeroCam iOS - Apple Design Resources (iOS 18 HIG) Script
// Cria um conceito 100% alinhado com as diretrizes e recursos de design oficiais da Apple (iOS 18 HIG).

(async function createZeroCamAppleHIG() {
  await figma.loadFontAsync({ family: "Inter", style: "Regular" });
  await figma.loadFontAsync({ family: "Inter", style: "Medium" });
  await figma.loadFontAsync({ family: "Inter", style: "Semi Bold" });
  await figma.loadFontAsync({ family: "Inter", style: "Bold" });

  // Cores oficiais do Sistema Apple (Dark Mode)
  const appleYellow = { r: 1.0, g: 0.84, b: 0.04 };    // #FFD60A (System Yellow)
  const systemGreen = { r: 0.19, g: 0.82, b: 0.35 };   // #30D158 (System Green)
  const bgBlack = { r: 0.0, g: 0.0, b: 0.0 };          // Pure OLED Black
  const gray6 = { r: 0.11, g: 0.11, b: 0.12 };         // #1C1C1E (System Gray 6)
  const gray5 = { r: 0.17, g: 0.17, b: 0.18 };         // #2C2C2E (System Gray 5)
  const gray4 = { r: 0.23, g: 0.23, b: 0.24 };         // #3A3A3C (System Gray 4)
  const gray3 = { r: 0.28, g: 0.28, b: 0.29 };         // #48484A (System Gray 3)
  const labelMuted = { r: 0.56, g: 0.56, b: 0.58 };    // #8E8E93 (System Gray 1)
  const white = { r: 1.0, g: 1.0, b: 1.0 };

  function solid(color, opacity = 1) {
    return [{ type: 'SOLID', color, opacity }];
  }

  // 1. Canvas de Apresentação
  const board = figma.createFrame();
  board.name = "ZeroCam — Apple Design Resources (iOS 18 HIG)";
  board.resize(1840, 1160);
  board.fills = solid(bgBlack);
  board.cornerRadius = 24;
  board.x = 0; board.y = 0;

  // Header Banner Apple
  const header = figma.createFrame();
  header.name = "Apple HIG Header";
  header.resize(1720, 130);
  header.x = 60; header.y = 40;
  header.fills = solid(gray6);
  header.cornerRadius = 24;
  header.strokes = solid(gray4);
  header.strokeWeight = 1;
  header.layoutMode = "VERTICAL";
  header.paddingLeft = 36;
  header.paddingTop = 26;
  header.itemSpacing = 8;
  board.appendChild(header);

  const tag = figma.createText();
  tag.fontName = { family: "Inter", style: "Bold" };
  tag.fontSize = 11;
  tag.characters = "APPLE DESIGN RESOURCES • IOS 18 HUMAN INTERFACE GUIDELINES";
  tag.fills = solid(appleYellow);
  header.appendChild(tag);

  const title = figma.createText();
  title.fontName = { family: "Inter", style: "Bold" };
  title.fontSize = 28;
  title.characters = "ZeroCam — Pure Optical Architecture";
  title.fills = solid(white);
  header.appendChild(title);

  const sub = figma.createText();
  sub.fontName = { family: "Inter", style: "Regular" };
  sub.fontSize = 13.5;
  sub.characters = "Desenvolvido com Dynamic Island oficial (126x37pt), Home Indicator (139x5pt), SF Pro Text Styles e Inset Grouped Sheets";
  sub.fills = solid(labelMuted);
  header.appendChild(sub);

  // Helper para criar dispositivo iPhone 16 Pro (393 × 852 pt)
  function createAppleDevice(name, x, y) {
    const phone = figma.createFrame();
    phone.name = name;
    phone.resize(393, 852);
    phone.x = x; phone.y = y;
    phone.fills = solid(bgBlack);
    phone.cornerRadius = 55;
    phone.strokes = solid(gray4);
    phone.strokeWeight = 2.5;
    phone.clipsContent = true;

    // Dynamic Island Oficial (126 × 37 pt)
    const island = figma.createFrame();
    island.name = "Dynamic Island";
    island.resize(126, 37);
    island.x = (393 - 126) / 2;
    island.y = 11;
    island.fills = solid(bgBlack);
    island.cornerRadius = 18.5;
    phone.appendChild(island);

    // Status Bar - Relógio e Sinais
    const time = figma.createText();
    time.fontName = { family: "Inter", style: "Semi Bold" };
    time.fontSize = 16;
    time.characters = "9:41";
    time.fills = solid(white);
    time.x = 38; time.y = 20;
    phone.appendChild(time);

    const statusIcons = figma.createText();
    statusIcons.fontName = { family: "Inter", style: "Semi Bold" };
    statusIcons.fontSize = 12;
    statusIcons.characters = "5G  100%";
    statusIcons.fills = solid(white);
    statusIcons.x = 312; statusIcons.y = 22;
    phone.appendChild(statusIcons);

    // Home Indicator Oficial (139 × 5 pt, Bottom 8 pt)
    const home = figma.createFrame();
    home.name = "Home Indicator";
    home.resize(139, 5);
    home.x = (393 - 139) / 2;
    home.y = 839;
    home.fills = solid(white, 0.8);
    home.cornerRadius = 2.5;
    phone.appendChild(home);

    return phone;
  }

  // 1. Ecrã Auto
  const s1 = createAppleDevice("01 · Apple Camera Auto", 60, 205);
  board.appendChild(s1);

  // 2. Ecrã Pro Manual
  const s2 = createAppleDevice("02 · Apple Camera Pro HUD", 493, 205);
  board.appendChild(s2);

  // 3. Ecrã Sheet
  const s3 = createAppleDevice("03 · Inset Grouped Sheet", 926, 205);
  board.appendChild(s3);

  // 4. Ecrã Darkroom
  const s4 = createAppleDevice("04 · Photos & EXIF Inspector", 1359, 205);
  board.appendChild(s4);

  figma.viewport.scrollAndZoomIntoView([board]);

  return { success: true, message: "Conceito Apple Design Resources gerado!" };
})();
