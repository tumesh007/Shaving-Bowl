/**
 * Tumesh's Shaving Bowl Customizer (v14)
 * Client-Side Interactive 3D Web App with Three.js & Binary STL Generator
 */

// Global State & Default Parameters
const state = {
    preset: 'standard', // 'standard' or 'travel'
    blade_storage_enabled: false,
    bowl_outer_diameter: 110,
    bowl_height: 45.6,
    wall_thickness: 3.0,
    export_texture_resolution: 0.50,
    diamond_scale: 0.40,
    diamond_ridge_height: 1.15,
    macro_hill_scale: 0.35,
    razor_handle_max_diameter: 15.0,
    razor_dock_angle: 25.0,
    head_rest_radius: 24.0,
    handle_width: 20.0,
    handle_projection: 27.0,
    emboss_line1: "Tumesh's",
    emboss_line2: "Shaving Bowl",
    emboss_height: 0.8,
    filamentColor: 0xd4af37,
    wireframe: false,
    showGrid: true,
    autoRotate: false
};

// Preset Profiles
const PRESETS = {
    standard: {
        bowl_outer_diameter: 110,
        bowl_height: 45.6,
        wall_thickness: 3.0,
        export_texture_resolution: 0.50,
        diamond_scale: 0.40,
        diamond_ridge_height: 1.15,
        macro_hill_scale: 0.35,
        razor_handle_max_diameter: 15.0,
        razor_dock_angle: 25.0,
        head_rest_radius: 24.0,
        handle_width: 20.0,
        handle_projection: 27.0,
        emboss_line1: "Tumesh's",
        emboss_line2: "Shaving Bowl"
    },
    travel: {
        bowl_outer_diameter: 84,
        bowl_height: 38.5,
        wall_thickness: 3.0,
        export_texture_resolution: 0.50,
        diamond_scale: 0.40,
        diamond_ridge_height: 1.15,
        macro_hill_scale: 0.35,
        razor_handle_max_diameter: 15.0,
        razor_dock_angle: 25.0,
        head_rest_radius: 22.0,
        handle_width: 18.0,
        handle_projection: 23.0,
        emboss_line1: "Tumesh's",
        emboss_line2: "Shaving Bowl"
    }
};

// Three.js Globals
let scene, camera, renderer, controls;
let bowlMesh, wireframeMesh, bedGrid;
let container;

// Initialize Application
window.addEventListener('DOMContentLoaded', () => {
    initThree();
    initUI();
    updateModel();
    animate();
});

function initThree() {
    container = document.getElementById('canvas-container');
    const width = container.clientWidth;
    const height = container.clientHeight;

    // Scene
    scene = new THREE.Scene();

    // Camera
    camera = new THREE.PerspectiveCamera(40, width / height, 1, 1000);
    camera.position.set(160, 150, 190);

    // Renderer
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    container.appendChild(renderer.domElement);

    // Orbit Controls
    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
    controls.target.set(15, 25, 0);
    controls.maxPolarAngle = Math.PI / 2 + 0.05; // Prevent flipping below bed

    // Lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.45);
    scene.add(ambientLight);

    const keyLight = new THREE.DirectionalLight(0xfff8e7, 0.85);
    keyLight.position.set(150, 220, 150);
    keyLight.castShadow = true;
    keyLight.shadow.mapSize.width = 2048;
    keyLight.shadow.mapSize.height = 2048;
    scene.add(keyLight);

    const fillLight = new THREE.DirectionalLight(0xa5c4d4, 0.4);
    fillLight.position.set(-150, 100, -100);
    scene.add(fillLight);

    const rimLight = new THREE.DirectionalLight(0xd4af37, 0.6);
    rimLight.position.set(0, 180, -160);
    scene.add(rimLight);

    // Bambu Lab A1 Mini Bed Grid (180x180 mm)
    bedGrid = new THREE.GridHelper(180, 18, 0xd4af37, 0x2e3340);
    bedGrid.position.y = 0;
    scene.add(bedGrid);

    // Bed Contact Shadow Plane
    const shadowGeo = new THREE.PlaneGeometry(180, 180);
    const shadowMat = new THREE.ShadowMaterial({ opacity: 0.28 });
    const shadowPlane = new THREE.Mesh(shadowGeo, shadowMat);
    shadowPlane.rotation.x = -Math.PI / 2;
    shadowPlane.position.y = -0.1;
    shadowPlane.receiveShadow = true;
    scene.add(shadowPlane);

    // Resize Handler
    window.addEventListener('resize', onWindowResize);
}

function onWindowResize() {
    const width = container.clientWidth;
    const height = container.clientHeight;
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
    renderer.setSize(width, height);
}

// -------------------------------------------------------------
// Procedural 3D Mesh Generator for Tumesh's Shaving Bowl (v14)
// -------------------------------------------------------------
function generateBowlGeometry() {
    const geometries = [];

    const outerRadius = state.bowl_outer_diameter / 2;
    const innerRadius = outerRadius - state.wall_thickness;
    const bowlHeight = state.bowl_height;
    const baseThick = 3.5;

    // 1. Bowl Body Shell (Revolution Profile with 46° Foot Cone)
    const segmentsRev = 64;
    const profilePoints = [];
    
    // Foot Cone tangent math
    const tan46 = Math.tan(46 * Math.PI / 180);
    const sin46 = Math.sin(46 * Math.PI / 180);
    const cos46 = Math.cos(46 * Math.PI / 180);
    const rTangent = outerRadius * sin46;
    const zTangent = bowlHeight - outerRadius * cos46;
    const rFoot = rTangent - zTangent / tan46;

    // Bed contact ring to outer rim
    profilePoints.push(new THREE.Vector2(0, 0));
    profilePoints.push(new THREE.Vector2(rFoot, 0));

    // Outer wall profile
    const steps = 30;
    for (let i = 1; i <= steps; i++) {
        const r = rFoot + (outerRadius - rFoot) * (i / steps);
        let z = 0;
        if (r < rTangent) {
            z = (r - rFoot) * tan46;
        } else {
            z = bowlHeight - Math.sqrt(Math.max(0, outerRadius * outerRadius - r * r));
        }
        profilePoints.push(new THREE.Vector2(r, Math.min(bowlHeight, z)));
    }
    // Rim width
    profilePoints.push(new THREE.Vector2(outerRadius, bowlHeight));
    profilePoints.push(new THREE.Vector2(innerRadius, bowlHeight));

    // Inner cavity profile
    for (let i = steps; i >= 0; i--) {
        const r = innerRadius * (i / steps);
        let z = bowlHeight - Math.sqrt(Math.max(0, innerRadius * innerRadius - r * r));
        z = Math.max(baseThick, z);
        profilePoints.push(new THREE.Vector2(r, z));
    }
    profilePoints.push(new THREE.Vector2(0, baseThick));

    const bowlLathe = new THREE.LatheGeometry(profilePoints, segmentsRev);
    geometries.push(bowlLathe);

    // 2. Lather Height-Field Floor Swirl Surface
    const floorRadius = Math.min(28, innerRadius * 0.55);
    const gridRes = 32;
    const floorGeo = new THREE.PlaneGeometry(floorRadius * 2, floorRadius * 2, gridRes, gridRes);
    floorGeo.rotateX(-Math.PI / 2);
    floorGeo.translate(0, baseThick + 0.1, 0);

    const pos = floorGeo.attributes.position;
    for (let i = 0; i < pos.count; i++) {
        const x = pos.getX(i);
        const z = pos.getZ(i);
        const dist = Math.sqrt(x * x + z * z);
        if (dist <= floorRadius) {
            // Seeded procedural diamond texture + macro undulation
            const diamondFreq = 1.0 / (state.diamond_scale * 8);
            const diamond = Math.sin(x * diamondFreq * 6.28) * Math.cos(z * diamondFreq * 6.28);
            const macro = Math.sin(x * 0.12) * Math.cos(z * 0.12) * state.macro_hill_scale;
            const h = (diamond * 0.5 + macro) * state.diamond_ridge_height;
            const fade = Math.cos((dist / floorRadius) * (Math.PI / 2));
            pos.setY(i, baseThick + 0.1 + Math.max(0, h * fade));
        } else {
            pos.setY(i, baseThick);
        }
    }
    floorGeo.computeVertexNormals();
    geometries.push(floorGeo);

    // 3. Redesigned Ergonomic Open-Loop Handle (v14: No Inverted Triangle at Base)
    const handleW = state.handle_width;
    const pillarX = outerRadius + state.handle_projection;
    const dockRaise = 8;
    const topZ = bowlHeight - 1 + dockRaise + 2;
    const bottomZ = 18.0; // Clean floating clearance above the bed

    // Vertical Grip Pillar
    const pillarGeo = new THREE.BoxGeometry(6, topZ - bottomZ, handleW);
    pillarGeo.translate(pillarX, bottomZ + (topZ - bottomZ) / 2, 0);
    geometries.push(pillarGeo);

    // Upper Bridge connecting to Dock
    const upperBridgeL = pillarX - (outerRadius + 2.0);
    const upperBridgeGeo = new THREE.BoxGeometry(upperBridgeL, 6, handleW);
    upperBridgeGeo.translate(outerRadius + 2.0 + upperBridgeL / 2, topZ, 0);
    geometries.push(upperBridgeGeo);

    // Lower Return Arch Sweeping Directly into Bowl Wall (at Z = 18 mm)
    // No downward triangle: ends at the bowl wall, leaves air gap below
    const lowerWallX = outerRadius - 8.0;
    const lowerArchL = pillarX - lowerWallX;
    const lowerArchGeo = new THREE.BoxGeometry(lowerArchL, 7, handleW);
    lowerArchGeo.translate(lowerWallX + lowerArchL / 2, bottomZ, 0);
    geometries.push(lowerArchGeo);

    // 4. Safety Razor Dock & Semicircle Head Rest Shelf
    const dockAngleRad = (90 - state.razor_dock_angle) * Math.PI / 180;
    const dockOuterR = state.razor_handle_max_diameter / 2 + 3.0;
    const dockLen = 18.0;

    const dockCyl = new THREE.CylinderGeometry(dockOuterR, dockOuterR, dockLen, 24, 1, true);
    dockCyl.rotateZ(dockAngleRad);
    dockCyl.translate(outerRadius + 2.0 + (dockLen / 2) * Math.cos(dockAngleRad),
                      bowlHeight - 1 + dockRaise + (dockLen / 2) * Math.sin(dockAngleRad),
                      0);
    geometries.push(dockCyl);

    // Half-Round Head Shelf
    const shelfR = state.head_rest_radius;
    const shelfGeo = new THREE.CylinderGeometry(shelfR, shelfR, 3.5, 24, 1, false, 0, Math.PI);
    shelfGeo.rotateZ(dockAngleRad);
    const shelfX = outerRadius + 2.0 + (dockLen + 3.0) * Math.cos(dockAngleRad);
    const shelfY = bowlHeight - 1 + dockRaise + (dockLen + 3.0) * Math.sin(dockAngleRad);
    shelfGeo.translate(shelfX, shelfY, 0);
    geometries.push(shelfGeo);

    // 5. Optional Blade Storage Drawer (if enabled)
    if (state.blade_storage_enabled) {
        const vaultW = 36;
        const vaultL = 65;
        const vaultH = 18;
        const vaultGeo = new THREE.BoxGeometry(vaultW, vaultH, vaultL);
        vaultGeo.translate(outerRadius + 14, vaultH / 2, 0);
        geometries.push(vaultGeo);
    }

    // Merge Geometries using Three.js BufferGeometryUtils / direct merge
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

// -------------------------------------------------------------
// Model Update & UI Sync
// -------------------------------------------------------------
function updateModel() {
    if (bowlMesh) {
        scene.remove(bowlMesh);
        if (bowlMesh.geometry) bowlMesh.geometry.dispose();
    }
    if (wireframeMesh) {
        scene.remove(wireframeMesh);
        if (wireframeMesh.geometry) wireframeMesh.geometry.dispose();
    }

    const geometry = generateBowlGeometry();

    // Material
    const material = new THREE.MeshStandardMaterial({
        color: state.filamentColor,
        roughness: 0.35,
        metalness: 0.25,
        flatShading: false
    });

    bowlMesh = new THREE.Mesh(geometry, material);
    bowlMesh.castShadow = true;
    bowlMesh.receiveShadow = true;
    scene.add(bowlMesh);

    // Wireframe Overlay
    const wireMat = new THREE.MeshBasicMaterial({
        color: 0x4a5568,
        wireframe: true,
        transparent: true,
        opacity: 0.3
    });
    wireframeMesh = new THREE.Mesh(geometry, wireMat);
    wireframeMesh.visible = state.wireframe;
    scene.add(wireframeMesh);

    // Update Dimensions & Stats Badge
    updateStats(geometry);
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
    const title = `Tumesh's Shaving Bowl v14 (${state.preset.toUpperCase()})`;
    for (let i = 0; i < 80; i++) {
        view.setUint8(i, i < title.length ? title.charCodeAt(i) : 0);
    }

    // Number of triangles
    view.setUint32(80, numTris, true);

    let offset = 84;
    for (let i = 0; i < numTris; i++) {
        const i0 = index ? index.getX(i * 3 + 0) : (i * 3 + 0);
        const i1 = index ? index.getX(i * 3 + 1) : (i * 3 + 1);
        const i2 = index ? index.getX(i * 3 + 2) : (i * 3 + 2);

        // Face Normal
        const nx = norm.getX(i0);
        const ny = norm.getY(i0);
        const nz = norm.getZ(i0);

        view.setFloat32(offset + 0, nx, true);
        view.setFloat32(offset + 4, ny, true);
        view.setFloat32(offset + 8, nz, true);

        // Vertex 1
        view.setFloat32(offset + 12, pos.getX(i0), true);
        view.setFloat32(offset + 16, pos.getY(i0), true);
        view.setFloat32(offset + 20, pos.getZ(i0), true);

        // Vertex 2
        view.setFloat32(offset + 24, pos.getX(i1), true);
        view.setFloat32(offset + 28, pos.getY(i1), true);
        view.setFloat32(offset + 32, pos.getZ(i1), true);

        // Vertex 3
        view.setFloat32(offset + 36, pos.getX(i2), true);
        view.setFloat32(offset + 40, pos.getY(i2), true);
        view.setFloat32(offset + 44, pos.getZ(i2), true);

        // Attribute byte count (0)
        view.setUint16(offset + 48, 0, true);

        offset += 50;
    }

    const blob = new Blob([buffer], { type: 'application/octet-stream' });
    const link = document.createElement('a');
    const filename = `Tumeshs_Shaving_Bowl_v14_${state.preset.toUpperCase()}_custom.stl`;
    link.href = URL.createObjectURL(blob);
    link.download = filename;
    link.click();
    URL.revokeObjectURL(link.href);
}

// -------------------------------------------------------------
// OpenSCAD Code Generator
// -------------------------------------------------------------
function generateOpenSCADSource() {
    return `/*
 * Tumesh's Shaving Bowl (v14) - Parametric Customizer Export
 * Generated at: ${new Date().toISOString()}
 * Presets: ${state.preset.toUpperCase()}
 */

bowl_preset = "${state.preset}";
is_standard = (bowl_preset == "standard");
bowl_outer_diameter = ${state.bowl_outer_diameter};
bowl_height = ${state.bowl_height};
wall_thickness = ${state.wall_thickness};

preview_mode = false;
export_texture_resolution = ${state.export_texture_resolution.toFixed(2)};
terrain_preview_fn = 64;
rounded_fn = 20;

diamond_scale = ${state.diamond_scale.toFixed(2)};
diamond_ridge_height = ${state.diamond_ridge_height.toFixed(2)};
macro_hill_scale = ${state.macro_hill_scale.toFixed(2)};

blade_storage_enabled = ${state.blade_storage_enabled ? "true" : "false"};
handle_width = ${state.handle_width};

razor_dock_angle = ${state.razor_dock_angle};
razor_handle_max_diameter = ${state.razor_handle_max_diameter};
head_rest_radius = ${state.head_rest_radius};

emboss_enabled = true;
emboss_line1 = "${state.emboss_line1}";
emboss_line2 = "${state.emboss_line2}";
emboss_height = ${state.emboss_height};

// Include official v14 module definitions
include <travel_shaving_bowl.scad>;
`;
}

// -------------------------------------------------------------
// UI Event Listeners
// -------------------------------------------------------------
function initUI() {
    // Sliders & Number inputs
    const paramInputs = [
        'bowl_outer_diameter', 'bowl_height', 'wall_thickness',
        'export_texture_resolution', 'diamond_scale', 'diamond_ridge_height',
        'macro_hill_scale', 'razor_handle_max_diameter', 'razor_dock_angle',
        'head_rest_radius', 'handle_width', 'handle_projection', 'emboss_height'
    ];

    paramInputs.forEach(id => {
        const input = document.getElementById(id);
        const valLabel = document.getElementById(`val_${id}`);
        if (input) {
            input.addEventListener('input', (e) => {
                const val = parseFloat(e.target.value);
                state[id] = val;
                if (valLabel) valLabel.textContent = val;
                updateModel();
            });
        }
    });

    // Text inputs
    ['emboss_line1', 'emboss_line2'].forEach(id => {
        const input = document.getElementById(id);
        if (input) {
            input.addEventListener('input', (e) => {
                state[id] = e.target.value;
                updateModel();
            });
        }
    });

    // Blade storage toggle
    const bladeStorageToggle = document.getElementById('blade_storage_enabled');
    const moistureWarning = document.getElementById('moisture-warning');
    if (bladeStorageToggle) {
        bladeStorageToggle.addEventListener('change', (e) => {
            state.blade_storage_enabled = e.target.checked;
            if (moistureWarning) {
                moistureWarning.style.display = e.target.checked ? 'none' : 'block';
            }
            updateModel();
        });
    }

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
            link.download = `travel_shaving_bowl_${state.preset}_custom.scad`;
            link.click();
            URL.revokeObjectURL(link.href);
        });
    }
}

function applyPreset(presetKey) {
    state.preset = presetKey;
    const p = PRESETS[presetKey];
    Object.keys(p).forEach(k => {
        state[k] = p[k];
        const input = document.getElementById(k);
        const valLabel = document.getElementById(`val_${k}`);
        if (input) {
            input.value = p[k];
            if (valLabel) valLabel.textContent = p[k];
        }
    });
    updateModel();
}

function setCameraView(viewKey) {
    switch (viewKey) {
        case 'iso':
            camera.position.set(160, 150, 190);
            controls.target.set(15, 25, 0);
            break;
        case 'top':
            camera.position.set(0, 240, 0);
            controls.target.set(0, 0, 0);
            break;
        case 'side':
            camera.position.set(220, 40, 0);
            controls.target.set(0, 25, 0);
            break;
        case 'front':
            camera.position.set(0, 40, 220);
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
