function createAndCompileShader(gl, source, type) {
	var s = gl.createShader(type);
	gl.shaderSource(s, source);
	gl.compileShader(s);
	if (gl.getShaderParameter(s, gl.COMPILE_STATUS) != 1) {
		throw gl.getShaderInfoLog(s);
	}
	return s;
}

function buildProgram(gl, vs, fs) {
	var program = gl.createProgram();
	gl.attachShader(program, vs);
	gl.attachShader(program, fs);
	gl.linkProgram(program);
 
	if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
		throw(gl.getProgramInfoLog(program));
		return 0;
	}	
	gl.useProgram(program);
	return program;
}

function parseProgram(gl, vertScriptId, fragScriptId) {
  var vertSrc = document.getElementById(vertScriptId).innerHTML;
  var fragSrc = document.getElementById(fragScriptId).innerHTML
	var vs = createAndCompileShader(gl, vertSrc, gl.VERTEX_SHADER);
	var fs = createAndCompileShader(gl, fragSrc, gl.FRAGMENT_SHADER);
	
	return buildProgram(gl, vs, fs);
}

function loadTexture(gl, src) {
  var texture = gl.createTexture();
  texture.image = new Image();
  texture.image.onload = function() {
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);
    gl.texImage2D(
      gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, 
      gl.UNSIGNED_BYTE, texture.image
    );
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.bindTexture(gl.TEXTURE_2D, null);    
  }
 
  texture.image.src = src;
  return texture;
}

function buildPlane(gl, sx, sz, nx, nz) {
  sx = sx || 1;
  sz = sz || 1;
  nx = nx || 10;
  nz = nz || 10;
  
  var vertices = [];
  var texCoords = [];
  var indices = [];
  
  for(var z=0; z < nz; z++ ) {
    for(var x=0; x < nx; x++ ) {
      vertices.push(x/nx * sx - sx/2, 0, z/nz * sz - sz/2);
      texCoords.push(x/nx, z/nz);
      if (x < nx-1 && z < nz-1) {
        indices.push(z*nx + x, (z+1)*nx + x + 1, z*nx + x + 1);
        indices.push(z*nx + x, (z+1)*nx + x, (z+1)*nx + x + 1);
      }
    }    
  }
  
  var plane = new SimpleMesh();
  plane.addAttrib(gl, "a_position", vertices);
  plane.addAttrib(gl, "a_texCoord", texCoords, 2);    
  plane.setIndices(gl, indices);
  return plane;
}

function buildSphere(gl, r, nsides, nsegments) {
  r = r || 1;
  nsides = nsides || 30;
  nsegments = nsegments || 30;
	function degToRad(d) {
		return d/180 * Math.PI;
	}
	var mesh = {
		vertices : [],
		normals : [],
		texCoords : [],
		indices: []
	};
	
 	var dtheta = 180.0/nsegments;
 	var dphi   = 360.0/nsides;
	
	var estimatedNumPoints = (Math.floor(360/dtheta) + 1) * (Math.floor(180/dphi) + 1);
	
	//vertexStream.setNumVertices(estimatedNumPoints);
	//vertexStream.setNumIndices(estimatedNumPoints * 6);
	
	for (var theta=0, segment=0; theta<=180; theta+=dtheta, ++segment) {
		for (var phi=0, side=0; phi<=360; phi+=dphi, ++side) {
			var pos = {	
				x : (r * Math.sin(degToRad(theta)) * Math.sin(degToRad(phi))),
				y : (r * Math.cos(degToRad(theta))),
				z : (r * Math.sin(degToRad(theta)) * Math.cos(degToRad(phi)))
			};
			mesh.vertices.push(pos.x, pos.y, pos.z);
			mesh.normals.push(pos.x, pos.y, pos.z);
			mesh.texCoords.push(phi/360.0, theta/180.0);
			
			//na dolnym biegunie nie dodajemy juz face'ow
			if (segment == nsegments) continue;
			if (side == nsides) continue;

			mesh.indices.push((segment  )*(nsides+1) + side); 			
			mesh.indices.push((segment+1)*(nsides+1) + side);	
			mesh.indices.push((segment+1)*(nsides+1) + side + 1);
			
			mesh.indices.push((segment  )*(nsides+1) + side); 			
			mesh.indices.push((segment+1)*(nsides+1) + side + 1);
			mesh.indices.push((segment  )*(nsides+1) + side + 1);
			
					
			/*
			mesh.indices.push((segment  )*(nsides+1) + side); 
			mesh.indices.push((segment+1)*(nsides+1) + side);			
			mesh.indices.push((segment+1)*(nsides+1) + side + 1);
			mesh.indices.push((segment  )*(nsides+1) + side); 
			mesh.indices.push((segment+1)*(nsides+1) + side + 1);
			mesh.indices.push((segment  )*(nsides+1) + side + 1);
			*/
		}
	}
	
	var sphere = new SimpleMesh();
  sphere.addAttrib(gl, "a_position", mesh.vertices);
  sphere.addAttrib(gl, "a_normal", mesh.normals);  
  sphere.addAttrib(gl, "a_texCoord", mesh.texCoords, 2);    
  sphere.setIndices(gl, mesh.indices);
  return sphere;
	
	return mesh;
}

function initWebGL(canvasElementId) {
	var canvas = document.getElementById(canvasElementId);

	var gl = canvas.getContext('webgl', {antialias: true});
	if (gl === null) {
		gl = canvas.getContext('experimental-webgl', {antialias: true});
	}
	if (gl === null) {
		throw("Can't create webgl context!");
	}
	gl.clearColor(1.0, 0.0, 0.0, 0.0);
	gl.clearDepth(1.0);
	gl.enable(gl.DEPTH_TEST);
	gl.depthFunc(gl.LEQUAL);
	gl.viewport(0, 0, 1, 1);   
	
	return gl;
}

var checkErrorsLastError = 0;
function checkErrors(gl, msg) {
  msg = msg || "";
  var error = gl.getError();
  if (error && error != checkErrorsLastError) {
    checkErrorsLastError = error;
    // console.log("gl.error " + error + " " + msg);
  }
}

function SimpleMesh() {
	this.attribs = [];
}

SimpleMesh.prototype.addAttrib = function(gl, name, data, size) {
  size = size || 3
  
	var attrib = {};
	attrib.name = name;
	attrib.data = data;
	attrib.buffer = gl.createBuffer();  
	attrib.size = size;
  gl.bindBuffer(gl.ARRAY_BUFFER, attrib.buffer);
	gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(data), gl.STATIC_DRAW);
	this.attribs.push(attrib);
}

SimpleMesh.prototype.updateAttrib = function(gl, name, data) {
  var attrib = null;
  for(var i=0; i<this.attribs.length; i++) {
    if (this.attribs[i].name == name) {
      attrib = this.attribs[i];
      break;
    }
  }
  if (!attrib) {
    return;
  }
  gl.bindBuffer(gl.ARRAY_BUFFER, attrib.buffer);
	gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(data), gl.STATIC_DRAW);
}

SimpleMesh.prototype.setIndices = function(gl, data) {
  this.indices = {};
  this.indices.data = data;
  this.indices.buffer = gl.createBuffer();
	gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.indices.buffer);
  gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, 
    new Uint16Array(data), gl.STATIC_DRAW
  );
}

SimpleMesh.prototype.draw = function(gl, program, primitive) {
  primitive = primitive || gl.TRIANGLES;
  
  for(var i in this.attribs) {
    var attrib = this.attribs[i];
    if (attrib.location === undefined) {
      attrib.location = gl.getAttribLocation(program, attrib.name);      
      // console.log(attrib.name + " " + attrib.location);
    }
    if (attrib.location >= 0) {
      gl.bindBuffer(gl.ARRAY_BUFFER, attrib.buffer);
      gl.vertexAttribPointer(attrib.location, attrib.size, gl.FLOAT, false, 0, 0);
      gl.enableVertexAttribArray(attrib.location);
    }    
  }
  gl.drawElements(primitive, this.indices.data.length, gl.UNSIGNED_SHORT, 0);
}

SimpleMesh.prototype.destroy = function(gl) {
  gl.deleteBuffer(this.indices.buffer);
  for(var i in this.attribs) {
    gl.deleteBuffer(this.attribs[i].buffer);
  }
}

function Mat4(a) {
  if (a) {
    this.m = [];
    for(var i=0; i<4; i++) {
      this.m[i] = [];
      for(var j=0; j<4; j++) {
        this.m[i][j] = a.m[i][j];
      }
    }
  }
  else {
    this.m = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
  }	
}

Mat4.prototype.toGLArray = function() {
	var m = this.m;
	// return new Float32Array([
	//         m[0][0], m[1][0], m[2][0],  m[3][0],
	//         m[0][1], m[1][1], m[2][1],  m[3][1],
	//         m[0][2], m[1][2], m[2][2],  m[3][2],
	//         m[0][3], m[1][3], m[2][3],  m[3][3]
	//     ]);
    return new Float32Array([
       m[0][0], m[0][1], m[0][2],  m[0][3],
       m[1][0], m[1][1], m[1][2],  m[1][3],
       m[2][0], m[2][1], m[2][2],  m[2][3],
       m[3][0], m[3][1], m[3][2],  m[3][3]
   ]);
};

function lookAtMat4(cam, target, up) {
	var F = normVec3(subVec3(target, cam));
	var S = normVec3(crossVec3(F, normVec3(up)));
	var U = normVec3(crossVec3(S, F));
	
	var result = new Mat4();
	
	result.m[0][0] = S.x;
	result.m[1][0] = S.y;
	result.m[2][0] = S.z;
	result.m[3][0] = 0.0;
	
	result.m[0][1] = U.x;
	result.m[1][1] = U.y;
	result.m[2][1] = U.z;
	result.m[3][1] = 0.0;
	
	result.m[0][2] = -F.x;
	result.m[1][2] = -F.y;
	result.m[2][2] = -F.z;
	result.m[3][2] = 0.0;
	
	result.m[0][3] = 0.0;
	result.m[1][3] = 0.0;
	result.m[2][3] = 0.0;
	result.m[3][3] = 1.0;
		
	return multMat4(result, translateMat4(-cam.x, -cam.y, -cam.z));
}

function translateMat4(x, y, z) {
	var result = new Mat4();

	result.m[3][0] = x;
	result.m[3][1] = y;
	result.m[3][2] = z;
	
	return result; 
}

function multMat4(a, b) {
	var result = new Mat4();
	for (var r=0; r<4; r++)  {
		for (var c=0; c<4; c++) {
			var f = 0;			
			f += (a.m[0][r] * b.m[c][0]);
			f += (a.m[1][r] * b.m[c][1]);
			f += (a.m[2][r] * b.m[c][2]);
			f += (a.m[3][r] * b.m[c][3]);
			result.m[c][r] = f;
		}
	}
	return result;
}

function perspectiveMat4(fov, aspect, near,  far) {
	var angle;
	var cot;
	
	angle = fov / 2.0;
	angle = angle / 180.0 * Math.PI;
	
	cot = Math.cos(angle) / Math.sin(angle);
	
	var result = new Mat4();
	
	result.m[0][0] = cot / aspect;
	result.m[0][1] = 0.0;
	result.m[0][2] = 0.0;
	result.m[0][3] = 0.0;
	
	result.m[1][0] = 0.0;
	result.m[1][1] = cot;
	result.m[1][2] = 0.0;
	result.m[1][3] = 0.0;
	
	result.m[2][0] = 0.0;
	result.m[2][1] = 0.0;
	result.m[2][2] = -(far + near) / (far - near); //-1
	result.m[2][3] = -1.0;
	
	
	result.m[3][0] = 0.0;
	result.m[3][1] = 0.0;
	result.m[3][2] = -(2*far*near) / (far - near);//-2*near;
	result.m[3][3] = 0.0;
	
	return result; 
}

function invertMat4(m) {	
	var a = new Mat4(m);
	var b = new Mat4();
	
	var r, c;
	var cc;
	var rowMax; // Points to max abs value row in this column
	var row;
	var tmp;
	
	// Go through columns
	for (c=0; c<4; c++) {
		// Find the row with max value in this column
		rowMax = c;
		for (r=c+1; r<4; r++) {
			if (Math.abs(a.m[c][r]) > Math.abs(a.m[c][rowMax]))	{
				rowMax = r;
			}
		}
		
		// If the max value here is 0, we can't invert.  Return identity.
		if (a.m[rowMax][c] == 0.0)
			return new Mat4();
		
		// Swap row "rowMax" with row "c"
		for (cc=0; cc<4; cc++) {
			tmp = a.m[cc][c];
			a.m[cc][c] = a.m[cc][rowMax];
			a.m[cc][rowMax] = tmp;
			tmp = b.m[cc][c];
			b.m[cc][c] = b.m[cc][rowMax];
			b.m[cc][rowMax] = tmp;
		}
		
		// Now everything we do is on row "c".
		// Set the max cell to 1 by dividing the entire row by that value
		tmp = a.m[c][c];
		for (cc=0; cc<4; cc++) {
			a.m[cc][c] /= tmp;
			b.m[cc][c] /= tmp;
		}
		
		// Now do the other rows, so that this column only has a 1 and 0's
		for (row = 0; row < 4; row++) {
			if (row != c) {
				tmp = a.m[c][row];
				for (cc=0; cc<4; cc++){
					a.m[cc][row] -= a.m[cc][c] * tmp;
					b.m[cc][row] -= b.m[cc][c] * tmp;
				}
			}
		}
	}
	return a;
}

function multMat4Vec3(a, v) {
  v.w = 1.0;
  
  return {
    x : v.x * a.m[0][0] + v.y * a.m[1][0] + v.z * a.m[2][0] + v.w * a.m[3][0],
    y : v.x * a.m[0][1] + v.y * a.m[1][1] + v.z * a.m[2][1] + v.w * a.m[3][1],
    z : v.x * a.m[0][2] + v.y * a.m[1][2] + v.z * a.m[2][2] + v.w * a.m[3][2],
    w : v.x * a.m[0][3] + v.y * a.m[1][3] + v.z * a.m[2][3] + v.w * a.m[3][3]
  }
}

function crossVec3(a, b) {
    // a1b2 - a2b1, a2b0 - a0b2, a0b1 - a1b0
    return {
        x: a.y * b.z - a.z * b.y,
        y: a.z * b.x - a.x * b.z,
        z: a.x * b.y - a.y * b.x
    };
}

function dotVec3(a, b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

// a - b
function subVec3(a, b) {
    return {x: a.x - b.x, y: a.y - b.y, z: a.z - b.z};
}

// a -= b
function subVec3IP(a, b) {
    a.x -= b.x;
    a.y -= b.y;
    a.z -= b.z;
    return a;
}

// a + b
function addVec3(a, b) {
    return {x: a.x + b.x, y: a.y + b.y, z: a.z + b.z};
}

// a += b
function addVec3IP(a, b) {
    a.x += b.x;
    a.y += b.y;
    a.z += b.z;
    return a;
}

// a * b
function mulVec3(a, b) {
    return {x: a.x * b.x, y: a.y * b.y, z: a.z * b.z};
}
function scaleVec3(a, b) {
    return {x: a.x * b, y: a.y * b, z: a.z * b};
}

// a *= b
function mulVec3IP(a, b) {
    a.x *= b.x;
    a.y *= b.y;
    a.z *= b.z;
    return a;
}
function scaleVec3IP(a, b) {
    a.x *= b;
    a.y *= b;
    a.z *= b;
    return a;
}

// |a|
function magVec3(a) {
    var ax = a.x, ay = a.y, az = a.z;
    return Math.sqrt(ax * ax + ay * ay + az * az);
}

// a / |a|
function normVec3(a) {
    return scaleVec3(a, 1 / magVec3(a));
}

// Linear interpolation on the line along points |a| and |b|.    |d| is the
// position, where 0 is |a| and 1 is |b|.
function lerpVec3(a, b, u) {
    return {
        x: (b.x-a.x)*u + a.x,
        y: (b.y-a.y)*u + a.y,
        z: (b.z-a.z)*u + a.z
    }
}

function printVec3(v)
{
    print("{x: " + v.x + ", y: " + v.y + ", z: " + v.z + "}");
}   

function Shader(gl, vertScriptId, fragScriptId) {    
  this.uniforms = {};
  this.attribs = {};
  
  var vertSrc = document.getElementById(vertScriptId).innerHTML;
  var fragSrc = document.getElementById(fragScriptId).innerHTML
	var vs = createAndCompileShader(gl, vertSrc, gl.VERTEX_SHADER);
	var fs = createAndCompileShader(gl, fragSrc, gl.FRAGMENT_SHADER);
  this.program = buildProgram(gl, vs, fs);  
  
  this.scanVariables(gl, vertSrc);
  this.scanVariables(gl, fragSrc);  
}      

Shader.prototype.use = function(gl) {  
  this.gl = gl;
  gl.useProgram(this.program);
}       

Shader.prototype.scanVariables = function(gl, src) {
  //';' would be better than '\n' in case shader source was compressed
  //but doesn't work if there are comments
  //TODO(marcin) switch to reg ex
  var lines = src.split("\n");                                             
  for(var i in lines) {
    var line = lines[i];        
    if (line.indexOf("uniform") === 0) {
      var t = line.split(" "); //TODO(marcin) switch to reg ex
      var type = t[1];
      var name = t[2].replace(";", "");
      var setterFunc;
      switch(type) {
        case "mat4": setterFunc = gl.uniformMatrix4fv; break;
        case "vec4": setterFunc = gl.uniform4fv; break;
        case "vec3": setterFunc = gl.uniform3fv; break;
        case "vec2": setterFunc = gl.uniform2fv; break;        
        case "float": setterFunc = gl.uniform1f; break;
        case "sampler2D": setterFunc = gl.uniform1i; break;
        case "sampler3D": setterFunc = gl.uniform1i; break;
        case "samplerCube": setterFunc = gl.uniform1i; break;                
        default: break; // console.log("Unknown uniform type : \"" + line + "\"");        
      }
      this.uniforms[name] = {
        type: type,           
        location: gl.getUniformLocation(this.program, name),
        setterFunc: setterFunc
      }    
    } 
    if (line.indexOf("attribute") === 0) {
      var t = line.split(" "); //TODO(marcin) switch to reg ex
      var type = t[1];
      var name = t[2].replace(";", "");;      
      this.attribs[name] = {
        type: type,
        location: gl.getAttribLocation(this.program, name)
      }
    }
  }
}  

Shader.prototype.set = function(name, value) {
  var uniform = this.uniforms[name];
  if (uniform) {           
    if (uniform.setterFunc == this.gl.uniformMatrix4fv) {   
      uniform.setterFunc.call(this.gl, uniform.location, false, value)
    } 
    else {
      uniform.setterFunc.call(this.gl, uniform.location, value)
    }    
  } 
  else {
    console.log("Unknown uniform name : " + name);
  }
}       

Shader.prototype.getAttribute = function(name){ 
  return this.attribs[name];
}
