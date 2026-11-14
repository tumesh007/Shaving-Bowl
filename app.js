/**
 * Tumesh's Shaving Bowl Customizer (v14.2)
 * Client-Side Interactive 3D Web App with Three.js, STLLoader & Real-Time Dynamic Engraving
 */

// Global State
const state = {
    preset: 'standard', // 'standard' or 'travel'
    blade_storage_enabled: false,
    bowl_outer_diameter: 108,
    bowl_height: 45.0,
    wall_thickness: 3.0,
    diamond_scale: 0.40,
    diamond_ridge_height: 1.35,
    macro_hill_scale: 0.40,
    razor_handle_max_diameter: 15.0,
    razor_dock_angle: 25.0,
    head_rest_radius: 24.0,
    handle_width: 20.0,
    handle_projection: 16.0,
    emboss_line1: "Tumesh's",
    emboss_line2: "Shaving Bowl",
    emboss_height: 0.8,
    filamentColor: 0xd4af37,
    wireframe: false,
    showGrid: true,
    autoRotate: false
};

const PRESETS = {
    standard: {
        bowl_outer_diameter: 108,
        bowl_height: 45.0,
        wall_thickness: 3.0,
        diamond_scale: 0.40,
        diamond_ridge_height: 1.35,
        macro_hill_scale: 0.40,
        razor_handle_max_diameter: 15.0,
        razor_dock_angle: 25.0,
        head_rest_radius: 24.0,
        handle_width: 20.0,
        handle_projection: 16.0,
        emboss_line1: "Tumesh's",
        emboss_line2: "Shaving Bowl",
        stlFile: "Tumeshs_Shaving_Bowl_v14_2_STANDARD_bin.stl"
    },
    travel: {
        bowl_outer_diameter: 84,
        bowl_height: 38.5,
        wall_thickness: 3.0,
        diamond_scale: 0.40,
        diamond_ridge_height: 1.15,
        macro_hill_scale: 0.35,
        razor_handle_max_diameter: 15.0,
        razor_dock_angle: 25.0,
        head_rest_radius: 22.0,
        handle_width: 18.0,
        handle_projection: 13.0,
        emboss_line1: "Tumesh's",
        emboss_line2: "Shaving Bowl",
        stlFile: "Tumeshs_Shaving_Bowl_v14_1_TRAVEL_bin.stl"
    }
};

// Three.js Globals
let scene, camera, renderer, controls;
let bowlMesh, wireframeMesh, bedGrid, decalMesh;
let container, loadingOverlay, loadingText;
let stlCache = {};

// Initialize Application
window.addEventListener('DOMContentLoaded', () => {
    initThree();
    initUI();
    loadCurrentPresetModel();
    animate();
});

function initThree() {
    container = document.getElementById('canvas-container');
    loadingOverlay = document.getElementById('loading-overlay');
    loadingText = document.getElementById('loading-text');

    const width = container.clientWidth || window.innerWidth - 380;
    const height = container.clientHeight || window.innerHeight - 64;

    // Scene
    scene = new THREE.Scene();

    // Camera
    camera = new THREE.PerspectiveCamera(40, width / height, 1, 1000);
    camera.position.set(150, 140, 160);

    // Renderer
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.1;
    container.appendChild(renderer.domElement);

    // Orbit Controls
    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
    controls.target.set(10, 22, 0);
    controls.maxPolarAngle = Math.PI / 2 + 0.02; // Prevent flipping below print bed

    // Lighting Setup
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.45);
    scene.add(ambientLight);

    const keyLight = new THREE.DirectionalLight(0xfffaed, 0.9);
    keyLight.position.set(120, 200, 140);
    keyLight.castShadow = true;
    keyLight.shadow.mapSize.width = 2048;
    keyLight.shadow.mapSize.height = 2048;
    keyLight.shadow.bias = -0.0001;
    scene.add(keyLight);

    const fillLight = new THREE.DirectionalLight(0x90b5d0, 0.4);
    fillLight.position.set(-140, 80, -100);
    scene.add(fillLight);

    const rimLight = new THREE.DirectionalLight(0xd4af37, 0.65);
    rimLight.position.set(-20, 160, -150);
    scene.add(rimLight);

    // Bambu Lab A1 Mini Bed Grid (180x180 mm)
    bedGrid = new THREE.GridHelper(180, 18, 0xd4af37, 0x2e3340);
    bedGrid.position.y = 0;
    scene.add(bedGrid);

    // Bed Contact Shadow Plane
    const shadowGeo = new THREE.PlaneGeometry(180, 180);
    const shadowMat = new THREE.ShadowMaterial({ opacity: 0.35 });
    const shadowPlane = new THREE.Mesh(shadowGeo, shadowMat);
    shadowPlane.rotation.x = -Math.PI / 2;
    shadowPlane.position.y = -0.05;
    shadowPlane.receiveShadow = true;
    scene.add(shadowPlane);

    window.addEventListener('resize', onWindowResize);
}

function onWindowResize() {
    if (!container) return;
    const width = container.clientWidth;
    const height = container.clientHeight;
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
    renderer.setSize(width, height);
}

// -------------------------------------------------------------
// Production Model Loading via STLLoader
// -------------------------------------------------------------
function loadCurrentPresetModel() {
    const preset = PRESETS[state.preset];
    const stlFile = preset.stlFile;

    showLoading(true, `Loading ${state.preset.toUpperCase()} Production STL...`);

    // Check memory cache
    if (stlCache[stlFile]) {
        applyLoadedGeometry(stlCache[stlFile]);
        showLoading(false);
        return;
    }

    const loader = new THREE.STLLoader();
    loader.load(
        stlFile,
        (geometry) => {
            geometry.computeVertexNormals();
            stlCache[stlFile] = geometry;
            applyLoadedGeometry(geometry);
            showLoading(false);
        },
        (xhr) => {
            if (xhr.lengthComputable) {
                const pct = Math.round((xhr.loaded / xhr.total) * 100);
                if (loadingText) loadingText.textContent = `Loading ${state.preset.toUpperCase()} (${pct}%)...`;
            }
        },
        (error) => {
            console.warn("STLLoader fetch error (falling back to procedural preview):", error);
            const fallbackGeo = generateProceduralBowlGeometry();
            applyLoadedGeometry(fallbackGeo);
            showLoading(false);
        }
    );
}

function applyLoadedGeometry(geometry) {
    if (bowlMesh) {
        scene.remove(bowlMesh);
        if (bowlMesh.geometry && !stlCache[bowlMesh.geometry.name]) {
            bowlMesh.geometry.dispose();
        }
    }
    if (wireframeMesh) {
        scene.remove(wireframeMesh);
        if (wireframeMesh.geometry) wireframeMesh.geometry.dispose();
    }

    // Material with subtle sheen matching WOL3D textured PEI gold / PETG
    const material = new THREE.MeshStandardMaterial({
        color: state.filamentColor,
        roughness: 0.32,
        metalness: 0.22,
        flatShading: false
    });

    bowlMesh = new THREE.Mesh(geometry, material);
    bowlMesh.castShadow = true;
    bowlMesh.receiveShadow = true;
    scene.add(bowlMesh);

    // Wireframe overlay
    const wireMat = new THREE.MeshBasicMaterial({
        color: 0x4a5568,
        wireframe: true,
        transparent: true,
        opacity: 0.25
    });
    wireframeMesh = new THREE.Mesh(geometry, wireMat);
    wireframeMesh.visible = state.wireframe;
    scene.add(wireframeMesh);

    // Update real-time 3D text engraving decal
    updateEngravingDecal();

    // Update stats badge
    updateStats(geometry);
}

function showLoading(show, text="") {
    if (!loadingOverlay) return;
    if (show) {
        loadingOverlay.classList.remove('hidden');
        if (loadingText && text) loadingText.textContent = text;
    } else {
        loadingOverlay.classList.add('hidden');
    }
}

// -------------------------------------------------------------
// Real-Time Dynamic Engraving Decal (Curved Wall Projection)
// -------------------------------------------------------------
function updateEngravingDecal() {
    if (decalMesh) {
        scene.remove(decalMesh);
        if (decalMesh.geometry) decalMesh.geometry.dispose();
        if (decalMesh.material) decalMesh.material.dispose();
    }

    const outerR = state.bowl_outer_diameter / 2;
    const bowlH = state.bowl_height;

    // Create high-res dynamic 2D canvas for Pacifico cursive script
    const canvas = document.createElement('canvas');
    canvas.width = 1024;
    canvas.height = 512;
    const ctx = canvas.getContext('2d');

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Subtle emboss shadow & highlight
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    const line1 = state.emboss_line1 || "";
    const line2 = state.emboss_line2 || "";

    // Draw Line 1
    ctx.font = "bold 92px 'Pacifico', cursive";
    ctx.fillStyle = "rgba(0, 0, 0, 0.4)";
    ctx.fillText(line1, canvas.width / 2 + 2, 170 + 3);
    ctx.fillStyle = "#fff4cc";
    ctx.fillText(line1, canvas.width / 2, 170);

    // Draw Line 2
    ctx.font = "bold 80px 'Pacifico', cursive";
    ctx.fillStyle = "rgba(0, 0, 0, 0.4)";
    ctx.fillText(line2, canvas.width / 2 + 2, 330 + 3);
    ctx.fillStyle = "#fff4cc";
    ctx.fillText(line2, canvas.width / 2, 330);

    const texture = new THREE.CanvasTexture(canvas);
    texture.needsUpdate = true;

    // Curved surface arc positioned on the outer bowl wall opposite the handle (Z > 0)
    const arcAngle = 55 * (Math.PI / 180);
    const decalH = 26;
    const decalR = outerR + 0.15; // Placed right on the outer skin

    const decalGeo = new THREE.CylinderGeometry(decalR, decalR, decalH, 32, 1, true, -arcAngle / 2, arcAngle);
    // Rotate to face front opposite the handle
    decalGeo.rotateY(Math.PI / 2);

    const decalMat = new THREE.MeshBasicMaterial({
        map: texture,
        transparent: true,
        opacity: 0.92,
        side: THREE.DoubleSide,
        depthWrite: false
    });

    decalMesh = new THREE.Mesh(decalGeo, decalMat);
    decalMesh.position.set(0, bowlH * 0.58, 0);
    scene.add(decalMesh);

    // Synchronize HTML 2D preview banner
    const prev1 = document.getElementById('preview-text-line1');
    const prev2 = document.getElementById('preview-text-line2');
    if (prev1) prev1.textContent = line1;
    if (prev2) prev2.textContent = line2;
}

// -------------------------------------------------------------
// Fallback Procedural Geometry Generator (With Connected Geometry)
// -------------------------------------------------------------
function generateProceduralBowlGeometry() {
    const geometries = [];

    const outerRadius = state.bowl_outer_diameter / 2;
    const innerRadius = outerRadius - state.wall_thickness;
    const bowlHeight = state.bowl_height;
    const baseThick = 3.5;

    // 1. Bowl Profile Lathe
    const segmentsRev = 64;
    const profilePoints = [];
    
    const tan46 = Math.tan(46 * Math.PI / 180);
    const sin46 = Math.sin(46 * Math.PI / 180);
    const cos46 = Math.cos(46 * Math.PI / 180);
    const rTangent = outerRadius * sin46;
    const zTangent = bowlHeight - outerRadius * cos46;
    const rFoot = rTangent - zTangent / tan46;

    profilePoints.push(new THREE.Vector2(0, 0));
    profilePoints.push(new THREE.Vector2(rFoot, 0));

    const steps = 30;
    for (let i = 1; i <= steps; i++) {
        const r = rFoot + (outerRadius - rFoot) * (i / steps);
        let z = (r < rTangent) ? (r - rFoot) * tan46 : bowlHeight - Math.sqrt(Math.max(0, outerRadius * outerRadius - r * r));
        profilePoints.push(new THREE.Vector2(r, Math.min(bowlHeight, z)));
    }
    profilePoints.push(new THREE.Vector2(outerRadius, bowlHeight));
    profilePoints.push(new THREE.Vector2(innerRadius, bowlHeight));

    for (let i = steps; i >= 0; i--) {
        const r = innerRadius * (i / steps);
        let z = Math.max(baseThick, bowlHeight - Math.sqrt(Math.max(0, innerRadius * innerRadius - r * r)));
        profilePoints.push(new THREE.Vector2(r, z));
    }
    profilePoints.push(new THREE.Vector2(0, baseThick));

    const bowlLathe = new THREE.LatheGeometry(profilePoints, segmentsRev);
    geometries.push(bowlLathe);

    // 2. Micro-Diamond Lather Swirl Floor Surface
    const floorR = innerRadius * 0.72;
    const floorRes = 36;
    const floorGeo = new THREE.PlaneGeometry(floorR * 2, floorR * 2, floorRes, floorRes);
    floorGeo.rotateX(-Math.PI / 2);
    floorGeo.translate(0, baseThick + 0.15, 0);

    const pos = floorGeo.attributes.position;
    for (let i = 0; i < pos.count; i++) {
        const x = pos.getX(i);
        const z = pos.getZ(i);
        const dist = Math.sqrt(x * x + z * z);
        if (dist <= floorR) {
            const diamondFreq = 1.0 / (state.diamond_scale * 7);
            const diamond = Math.sin(x * diamondFreq * 6.28) * Math.cos(z * diamondFreq * 6.28);
            const macro = Math.sin(x * 0.14) * Math.cos(z * 0.14) * state.macro_hill_scale;
            const h = (diamond * 0.6 + macro) * state.diamond_ridge_height;
            const fade = Math.cos((dist / floorR) * (Math.PI / 2));
            pos.setY(i, baseThick + 0.15 + Math.max(0, h * fade));
        } else {
            pos.setY(i, baseThick);
        }
    }
    floorGeo.computeVertexNormals();
    geometries.push(floorGeo);

    // 3. Sliced Cylinder Handle (Connected & Merged)
    const pillarX = outerRadius + state.handle_projection;
    const dockOriginX = outerRadius + 2.0;
    const dockOriginY = bowlHeight - 1 + 8.0;
    const pillarTopY = dockOriginY + 1.5;
    const wallStartY = 12.0;
    const wallStartX = 34.0;

    // Strut curve connecting wall to pillar
    const strutL = Math.hypot(pillarX - wallStartX, pillarTopY - wallStartY);
    const strutAngle = Math.atan2(pillarTopY - wallStartY, pillarX - wallStartX);

    const strutGeo = new THREE.CylinderGeometry(state.handle_width * 0.38, state.handle_width * 0.5, strutL, 20);
    strutGeo.rotateZ(strutAngle - Math.PI / 2);
    strutGeo.translate((pillarX + wallStartX) / 2, (pillarTopY + wallStartY) / 2, 0);
    geometries.push(strutGeo);

    // Razor Cradle Tube
    const dockOuterR = state.razor_handle_max_diameter / 2 + 3.0;
    const dockLen = 18.0;
    const dockAngleRad = (90 - state.razor_dock_angle) * Math.PI / 180;

    const dockCyl = new THREE.CylinderGeometry(dockOuterR, dockOuterR, dockLen, 24);
    dockCyl.rotateZ(dockAngleRad);
    dockCyl.translate(dockOriginX + (dockLen / 2) * Math.cos(dockAngleRad),
                      dockOriginY + (dockLen / 2) * Math.sin(dockAngleRad),
                      0);
    geometries.push(dockCyl);

    // Merge into single buffer geometry
    return mergeBufferGeometries(geometries);
}

function mergeBufferGeometries(geometries) {
    let totalPositions = 0;
    let totalNormals = 0;
    let totalIndices = 0;

    geometries.forEach(geo => {
        totalPositions += geo.attributes.position.array.length;
        if (geo.attributes.normal) totalNormals += geo.attributes.normal.array.length;
        if (geo.index) totalIndices += geo.index.array.length;
        else totalIndices += (geo.attributes.position.array.length / 3);
    });

    const mergedPos = new Float32Array(totalPositions);
    const mergedNorm = new Float32Array(totalPositions);
    const mergedIndices = [];

    let posOffset = 0;
    let vertexOffset = 0;

    geometries.forEach(geo => {
        const posArray = geo.attributes.position.array;
        mergedPos.set(posArray, posOffset);

        if (geo.attributes.normal) {
            mergedNorm.set(geo.attributes.normal.array, posOffset);
        }

        if (geo.index) {
            const indArray = geo.index.array;
            for (let i = 0; i < indArray.length; i++) {
                mergedIndices.push(indArray[i] + vertexOffset);
            }
        } else {
            const count = posArray.length / 3;
            for (let i = 0; i < count; i++) {
                mergedIndices.push(i + vertexOffset);
            }
        }

        vertexOffset += (posArray.length / 3);
        posOffset += posArray.length;
    });

    const mergedGeo = new THREE.BufferGeometry();
    mergedGeo.setAttribute('position', new THREE.BufferAttribute(mergedPos, 3));
    mergedGeo.setAttribute('normal', new THREE.BufferAttribute(mergedNorm, 3));
    mergedGeo.setIndex(mergedIndices);
    mergedGeo.computeVertexNormals();
    return mergedGeo;
}

function updateStats(geo) {
    geo.computeBoundingBox();
    const bb = geo.boundingBox;
    const sizeX = Math.round(bb.max.x - bb.min.x);
    const sizeZ = Math.round(bb.max.z - bb.min.z);
    const sizeY = Math.round(bb.max.y - bb.min.y);

    document.getElementById('stat-dims').textContent = `${sizeX} × ${sizeZ} × ${sizeY} mm`;
    const capacity = state.preset === 'standard' ? '~241 mL' : '~104 mL';
    document.getElementById('stat-volume').textContent = capacity;

    const margin = 180 - Math.max(sizeX, sizeZ);
    document.getElementById('stat-margin').textContent = `+${margin} mm (A1 Mini)`;

    const triangleCount = geo.index ? Math.round(geo.index.count / 3) : Math.round(geo.attributes.position.count / 3);
    document.getElementById('stat-triangles').textContent = `${triangleCount.toLocaleString()}`;
}

// -------------------------------------------------------------
// Binary STL Exporter (Runs 100% Client-Side)
// -------------------------------------------------------------
function exportBinarySTL() {
    if (!bowlMesh || !bowlMesh.geometry) return;

    const geo = bowlMesh.geometry;
    const pos = geo.attributes.position;
    const norm = geo.attributes.normal;
    const index = geo.index;
    const numTris = index ? (index.count / 3) : (pos.count / 3);

    const bufferSize = 84 + numTris * 50;
    const buffer = new ArrayBuffer(bufferSize);
    const view = new DataView(buffer);

    // 80-byte header
    const title = `Tumesh's Shaving Bowl v14.2 (${state.preset.toUpperCase()})`;
    for (let i = 0; i < 80; i++) {
        view.setUint8(i, i < title.length ? title.charCodeAt(i) : 0);
    }

    view.setUint32(80, numTris, true);

    let offset = 84;
    for (let i = 0; i < numTris; i++) {
        const i0 = index ? index.getX(i * 3 + 0) : (i * 3 + 0);
        const i1 = index ? index.getX(i * 3 + 1) : (i * 3 + 1);
        const i2 = index ? index.getX(i * 3 + 2) : (i * 3 + 2);

        view.setFloat32(offset + 0, norm.getX(i0), true);
        view.setFloat32(offset + 4, norm.getY(i0), true);
        view.setFloat32(offset + 8, norm.getZ(i0), true);

        view.setFloat32(offset + 12, pos.getX(i0), true);
        view.setFloat32(offset + 16, pos.getY(i0), true);
        view.setFloat32(offset + 20, pos.getZ(i0), true);

        view.setFloat32(offset + 24, pos.getX(i1), true);
        view.setFloat32(offset + 28, pos.getY(i1), true);
        view.setFloat32(offset + 32, pos.getZ(i1), true);

        view.setFloat32(offset + 36, pos.getX(i2), true);
        view.setFloat32(offset + 40, pos.getY(i2), true);
        view.setFloat32(offset + 44, pos.getZ(i2), true);

        view.setUint16(offset + 48, 0, true);
        offset += 50;
    }

    const blob = new Blob([buffer], { type: 'application/octet-stream' });
    const link = document.createElement('a');
    const filename = `Tumeshs_Shaving_Bowl_v14_2_${state.preset.toUpperCase()}_custom.stl`;
    link.href = URL.createObjectURL(blob);
    link.download = filename;
    link.click();
    URL.revokeObjectURL(link.href);
}

// -------------------------------------------------------------
// OpenSCAD Parametric Code Generator
// -------------------------------------------------------------
function generateOpenSCADSource() {
    return `/*
 * Tumesh's Shaving Bowl (v14.2) - Parametric Customizer Source
 * Generated: ${new Date().toISOString()}
 * Preset: ${state.preset.toUpperCase()}
 */

bowl_preset = "${state.preset}";
is_standard = (bowl_preset == "standard");
bowl_outer_diameter = ${state.bowl_outer_diameter};
bowl_height = ${state.bowl_height};
wall_thickness = ${state.wall_thickness};

preview_mode = false;
terrain_preview_fn = 64;
rounded_fn = 20;

diamond_scale = ${state.diamond_scale.toFixed(2)};
diamond_ridge_height = ${state.diamond_ridge_height.toFixed(2)};
macro_hill_scale = ${state.macro_hill_scale.toFixed(2)};

blade_storage_enabled = ${state.blade_storage_enabled ? "true" : "false"};
handle_width = ${state.handle_width};

dock_raise = 8.0;
dock_offset_x = 2.0;
razor_dock_angle = ${state.razor_dock_angle};
razor_handle_max_diameter = ${state.razor_handle_max_diameter};
head_rest_radius = ${state.head_rest_radius};

emboss_enabled = true;
emboss_line1 = "${state.emboss_line1}";
emboss_line2 = "${state.emboss_line2}";
emboss_height = ${state.emboss_height};

// Include official v14.2 parametric definitions
include <travel_shaving_bowl_v14_2.scad>;
`;
}

// -------------------------------------------------------------
// UI Event Handlers
// -------------------------------------------------------------
function initUI() {
    // Engraving text inputs
    ['emboss_line1', 'emboss_line2'].forEach(id => {
        const input = document.getElementById(id);
        if (input) {
            input.addEventListener('input', (e) => {
                state[id] = e.target.value;
                updateEngravingDecal();
            });
        }
    });

    // Emboss relief height
    const embossHeightInput = document.getElementById('emboss_height');
    if (embossHeightInput) {
        embossHeightInput.addEventListener('input', (e) => {
            const val = parseFloat(e.target.value);
            state.emboss_height = val;
            const lbl = document.getElementById('val_emboss_height');
            if (lbl) lbl.textContent = val.toFixed(1);
        });
    }

    // Sliders
    const paramInputs = [
        'bowl_outer_diameter', 'bowl_height', 'wall_thickness',
        'diamond_scale', 'diamond_ridge_height', 'macro_hill_scale',
        'razor_handle_max_diameter', 'razor_dock_angle',
        'head_rest_radius', 'handle_width', 'handle_projection'
    ];

    paramInputs.forEach(id => {
        const input = document.getElementById(id);
        const valLabel = document.getElementById(`val_${id}`);
        if (input) {
            input.addEventListener('input', (e) => {
                const val = parseFloat(e.target.value);
                state[id] = val;
                if (valLabel) valLabel.textContent = val;
            });
        }
    });

    // Preset Buttons
    document.querySelectorAll('.segment-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.segment-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            const preset = btn.getAttribute('data-preset');
            applyPreset(preset);
        });
    });

    // Filament Color Dots
    document.querySelectorAll('.color-dot').forEach(dot => {
        dot.addEventListener('click', () => {
            document.querySelectorAll('.color-dot').forEach(d => d.classList.remove('active'));
            dot.classList.add('active');
            const hex = parseInt(dot.getAttribute('data-color'), 16);
            state.filamentColor = hex;
            if (bowlMesh) bowlMesh.material.color.setHex(hex);
        });
    });

    // Render Toggles
    const wireframeToggle = document.getElementById('toggle-wireframe');
    if (wireframeToggle) {
        wireframeToggle.addEventListener('change', (e) => {
            state.wireframe = e.target.checked;
            if (wireframeMesh) wireframeMesh.visible = state.wireframe;
        });
    }

    const gridToggle = document.getElementById('toggle-grid');
    if (gridToggle) {
        gridToggle.addEventListener('change', (e) => {
            if (bedGrid) bedGrid.visible = e.target.checked;
        });
    }

    const autoRotateToggle = document.getElementById('toggle-autorotate');
    if (autoRotateToggle) {
        autoRotateToggle.addEventListener('change', (e) => {
            state.autoRotate = e.target.checked;
            controls.autoRotate = state.autoRotate;
            controls.autoRotateSpeed = 2.0;
        });
    }

    // Camera Presets
    document.querySelectorAll('.cam-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.cam-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            const view = btn.getAttribute('data-view');
            setCameraView(view);
        });
    });

    // Accordions
    document.querySelectorAll('.accordion-header').forEach(header => {
        header.addEventListener('click', () => {
            const item = header.parentElement;
            item.classList.toggle('open');
        });
    });

    // Reset Button
    document.getElementById('btn-reset').addEventListener('click', () => {
        applyPreset(state.preset);
    });

    // Export STL Button
    document.getElementById('btn-export-stl').addEventListener('click', () => {
        exportBinarySTL();
    });

    // SCAD Modal Dialog
    const modalScad = document.getElementById('modal-scad');
    const btnDownloadScad = document.getElementById('btn-download-scad');
    const modalClose = document.getElementById('modal-close');
    const btnCopyScad = document.getElementById('btn-copy-scad');
    const btnSaveScad = document.getElementById('btn-save-scad');
    const scadOutput = document.getElementById('scad-code-output');

    if (btnDownloadScad) {
        btnDownloadScad.addEventListener('click', () => {
            scadOutput.value = generateOpenSCADSource();
            modalScad.classList.remove('hidden');
        });
    }

    if (modalClose) {
        modalClose.addEventListener('click', () => {
            modalScad.classList.add('hidden');
        });
    }

    if (btnCopyScad) {
        btnCopyScad.addEventListener('click', () => {
            scadOutput.select();
            navigator.clipboard.writeText(scadOutput.value);
            btnCopyScad.textContent = "Copied!";
            setTimeout(() => { btnCopyScad.textContent = "Copy to Clipboard"; }, 2000);
        });
    }

    if (btnSaveScad) {
        btnSaveScad.addEventListener('click', () => {
            const code = generateOpenSCADSource();
            const blob = new Blob([code], { type: 'text/plain' });
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = `travel_shaving_bowl_${state.preset}_v14_2_custom.scad`;
            link.click();
            URL.revokeObjectURL(link.href);
        });
    }
}

function applyPreset(presetKey) {
    state.preset = presetKey;
    const p = PRESETS[presetKey];
    Object.keys(p).forEach(k => {
        if (k === 'stlFile') return;
        state[k] = p[k];
        const input = document.getElementById(k);
        const valLabel = document.getElementById(`val_${k}`);
        if (input) {
            input.value = p[k];
            if (valLabel) valLabel.textContent = p[k];
        }
    });
    loadCurrentPresetModel();
}

function setCameraView(viewKey) {
    switch (viewKey) {
        case 'iso':
            camera.position.set(150, 140, 160);
            controls.target.set(10, 22, 0);
            break;
        case 'top':
            camera.position.set(0, 210, 0);
            controls.target.set(0, 0, 0);
            break;
        case 'side':
            camera.position.set(200, 35, 0);
            controls.target.set(10, 25, 0);
            break;
        case 'front':
            camera.position.set(0, 35, 200);
            controls.target.set(0, 25, 0);
            break;
    }
    controls.update();
}

// -------------------------------------------------------------
// Render Loop
// -------------------------------------------------------------
function animate() {
    requestAnimationFrame(animate);
    controls.update();
    renderer.render(scene, camera);
}
