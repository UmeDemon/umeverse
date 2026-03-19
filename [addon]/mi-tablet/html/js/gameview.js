/**
 * MI Tablet - GameView Module
 * WebGL-based game screen capture for screenshot functionality
 * Based on the fivem-game-view pattern used by LB Phone
 */

class GameView {
    constructor() {
        // Vertex shader - simple pass-through
        this.vertexShaderSrc = `
            attribute vec2 a_position;
            attribute vec2 a_texcoord;
            varying vec2 textureCoordinate;
            void main() {
                gl_Position = vec4(a_position, 0.0, 1.0);
                textureCoordinate = a_texcoord;
            }
        `;

        // Fragment shader - simple texture sampling
        this.fragmentShaderSrc = `
            varying highp vec2 textureCoordinate;
            uniform sampler2D external_texture;
            void main() {
                gl_FragColor = texture2D(external_texture, textureCoordinate);
            }
        `;

        this.canvas = null;
        this.gl = null;
        this.interval = null;
        this.gameView = null;
    }

    /**
     * Compile a shader
     */
    makeShader(gl, type, src) {
        const shader = gl.createShader(type);
        gl.shaderSource(shader, src);
        gl.compileShader(shader);
        
        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
            console.error('[GameView] Shader compilation error:', gl.getShaderInfoLog(shader));
            return null;
        }
        
        return shader;
    }

    /**
     * Create a texture with the magic hook sequence for capturing game view
     */
    createTexture(gl) {
        const tex = gl.createTexture();
        const texPixels = new Uint8Array([0, 0, 255, 255]);

        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.texImage2D(
            gl.TEXTURE_2D,
            0,
            gl.RGBA,
            1,
            1,
            0,
            gl.RGBA,
            gl.UNSIGNED_BYTE,
            texPixels
        );

        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);

        // Magic hook sequence - this triggers FiveM's game view capture
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);

        // Reset to normal
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

        return tex;
    }

    /**
     * Create vertex and texture coordinate buffers
     */
    createBuffers(gl) {
        // Vertex positions for a full-screen quad
        const vertexBuff = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuff);
        gl.bufferData(
            gl.ARRAY_BUFFER,
            new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]),
            gl.STATIC_DRAW
        );

        // Texture coordinates
        const texBuff = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, texBuff);
        gl.bufferData(
            gl.ARRAY_BUFFER,
            new Float32Array([0, 0, 1, 0, 0, 1, 1, 1]),
            gl.STATIC_DRAW
        );

        return { vertexBuff, texBuff };
    }

    /**
     * Create and link the shader program
     */
    createProgram(gl) {
        const vertexShader = this.makeShader(gl, gl.VERTEX_SHADER, this.vertexShaderSrc);
        const fragmentShader = this.makeShader(gl, gl.FRAGMENT_SHADER, this.fragmentShaderSrc);

        if (!vertexShader || !fragmentShader) {
            return null;
        }

        const program = gl.createProgram();

        gl.attachShader(program, vertexShader);
        gl.attachShader(program, fragmentShader);
        gl.linkProgram(program);

        if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
            console.error('[GameView] Program linking error:', gl.getProgramInfoLog(program));
            return null;
        }

        gl.useProgram(program);

        const vloc = gl.getAttribLocation(program, 'a_position');
        const tloc = gl.getAttribLocation(program, 'a_texcoord');

        return { program, vloc, tloc };
    }

    /**
     * Initialize all WebGL components
     */
    createStuff(gl) {
        const tex = this.createTexture(gl);
        const result = this.createProgram(gl);
        
        if (!result) {
            console.error('[GameView] Failed to create program');
            return false;
        }
        
        const { program, vloc, tloc } = result;
        const { vertexBuff, texBuff } = this.createBuffers(gl);

        gl.useProgram(program);
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.uniform1i(gl.getUniformLocation(program, 'external_texture'), 0);

        gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuff);
        gl.vertexAttribPointer(vloc, 2, gl.FLOAT, false, 0, 0);
        gl.enableVertexAttribArray(vloc);

        gl.bindBuffer(gl.ARRAY_BUFFER, texBuff);
        gl.vertexAttribPointer(tloc, 2, gl.FLOAT, false, 0, 0);
        gl.enableVertexAttribArray(tloc);

        gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
        
        return true;
    }

    /**
     * Render a frame
     */
    render(gl, gameView) {
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
        gl.finish();

        let render = () => {};
        gameView.animationFrame = requestAnimationFrame(render);
    }

    /**
     * Create and initialize the game view capture
     */
    createGameView(canvas) {
        this.canvas = canvas;
        
        const gl = this.canvas.getContext('webgl', {
            antialias: false,
            depth: false,
            stencil: false,
            alpha: false,
            desynchronized: true,
            failIfMajorPerformanceCaveat: false,
            preserveDrawingBuffer: true // Important for toDataURL/toBlob
        });

        if (!gl) {
            console.error('[GameView] Failed to get WebGL context');
            return null;
        }

        this.gl = gl;

        this.gameView = {
            canvas,
            gl,
            animationFrame: undefined,
            resize: (width, height) => {
                gl.viewport(0, 0, width, height);
                gl.canvas.width = width;
                gl.canvas.height = height;
            }
        };

        if (!this.createStuff(gl)) {
            return null;
        }

        // Start render loop
        this.interval = setInterval(() => {
            this.render(gl, this.gameView);
        }, 0);

        console.log('[GameView] Game view capture initialized');
        return this.gameView;
    }

    /**
     * Capture the current frame as a data URL
     */
    captureFrame(mimeType = 'image/webp', quality = 0.92) {
        if (!this.canvas) {
            console.error('[GameView] No canvas available for capture');
            return null;
        }

        try {
            return this.canvas.toDataURL(mimeType, quality);
        } catch (error) {
            console.error('[GameView] Error capturing frame:', error);
            return null;
        }
    }

    /**
     * Capture the current frame as a Blob
     */
    captureFrameAsBlob(mimeType = 'image/webp', quality = 0.92) {
        return new Promise((resolve, reject) => {
            if (!this.canvas) {
                reject(new Error('No canvas available for capture'));
                return;
            }

            try {
                this.canvas.toBlob(
                    (blob) => {
                        if (blob) {
                            resolve(blob);
                        } else {
                            reject(new Error('Failed to create blob'));
                        }
                    },
                    mimeType,
                    quality
                );
            } catch (error) {
                reject(error);
            }
        });
    }

    /**
     * Stop the game view capture
     */
    stop() {
        if (this.interval) {
            clearInterval(this.interval);
            this.interval = null;
        }

        if (this.gameView && this.gameView.animationFrame) {
            cancelAnimationFrame(this.gameView.animationFrame);
        }

        if (this.canvas) {
            this.canvas.style.display = 'none';
        }

        console.log('[GameView] Game view capture stopped');
    }

    /**
     * Show/hide the canvas
     */
    setVisible(visible) {
        if (this.canvas) {
            this.canvas.style.display = visible ? 'block' : 'none';
        }
    }
}

// Create global instance
window.GameView = GameView;
window.gameViewInstance = new GameView();
