var Nine5 = (function() {
  function JSONManager(gl) {
    var queue_ = [ ];
    var inflight_ = 0;

    var years_ = [ ];

    function makeVBO(data) {
      var fa = new Float32Array(data.length / 5 * 8);
      for (var i = 0, k = 0, il = data.length; i < il; i += 5) {
        var q_lat = data[i];  // Encoded * 1000.
        var q_long = data[i+1];  // Encoded * 1000.
        var q_time = data[i+2];  // Encoded as integer seconds from epoch.
        // We add 1 to the magnitude so we know both ends of 0 magnitude lines.
        var q_m = data[i+3] + 1;  // Encoded * 10.
        var q_depth  = data[i+4];  // Encoded * 10.

        // We want both points of the line to know the magnitude so it can
        // filter based on u_min_m, but we also want to know which end of the
        // line is which, so encode +/- m for the different ends of the line.
        fa[k++] = q_lat; fa[k++] = q_long; fa[k++] = -q_m; fa[k++] = q_depth;
        fa[k++] = q_lat; fa[k++] = q_long; fa[k++] = q_m; fa[k++] = q_depth;
      }
      var num = fa.length / 4;
      var buffer = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
      gl.bufferData(gl.ARRAY_BUFFER, fa, gl.STATIC_DRAW);
      fa = null; data = null;  // From here out only the VBO data should exist.
      return {buffer: buffer, num: num, sig: null};
    }

    function ensureYearObject(year) {
      if (years_[year] === undefined)
        years_[year] = { };
    }

    window.month_loaded = function(year, month, data) {
      if (window.console) window.console.log('loaded: ' + year + ' ' + month);
      ensureYearObject(year);
      years_[year][month] = makeVBO(data);
      data = null;
    };

    window.sig_month_loaded = function(year, month, data) {
      // The month VBO should have already been created, attach the
      // significant event data.
      years_[year][month].sig = data;
    };

    function fetchData(year, month) {
      ensureYearObject(year);

      if (years_[year][month] === null)
        return;  // Already inflight.

      if (years_[year][month] !== undefined)
        return;  // Already fetched.

      years_[year][month] = null;  // Mark as inflight.

      ++inflight_;
      var s = document.createElement('script');
      s.onload = function() {
        --inflight_;
        tryQueue();
      };
      s.onerror = function() {
        --inflight_;
        // Already marked as queued, just put it back in after 5 seconds.
        setTimeout(function() {
          queue_.push({year: year, month: month});
          tryQueue();
        }, 5000);
        // if (window.console) window.console.log("failed to fetch json data.");
      };
      s.src = 'data/epic/' + year + '_' + month + '.js';
      document.body.appendChild(s);
    }

    function tryQueue() {
      if (inflight_ < 2 && queue_.length > 0) {
        //var ym = queue_.shift();
        var ym = queue_.pop();
        fetchData(ym.year, ym.month);
      }
    }

    this.getVBOForMonth = function(year, month) {
      ensureYearObject(year);
      var data = years_[year][month];
      if (data === null)  // Inflight.
        return {buffer: null, num: 0, sig: null};
      if (data === undefined) {  // Not inflight, enqueue.
        // if (window.console) window.console.log('Enqueueing');
        queue_.push({year: year, month: month});
        tryQueue();
        return {buffer: null, num: 0, sig: null};
      }
      return data;  // Data was available.
    };
  }

  // Generate / draw / scroll / select a range of time on a timeline.
  // This code was written pretty quickly, and it's pretty special cased to
  // our specific look, feel, time range, etc.
  function Timeline(canvas) {
    var ctx = canvas.getContext('2d');
    var real_width = canvas.width;
    var width = real_width - 50;  // 5 pixel margins on both sides.
    var width_offset = 25;
    var kScrollM = 25;
    var height = canvas.height;
    ctx.font = '10px georgia';
    var kStartYear = 1977;
    var kPixelsPerMonth = 4;
    var kLineBottom = 10;
    var kNumberOfMonths = (2011 - kStartYear) * 12;
    var kNumberOfMonthsVisible = (width / kPixelsPerMonth) >> 0;
    // Number of months from start.
    var cursor = kNumberOfMonths - 12;
    // Number of months we're scroll from the start.
    var scroll_cursor = cursor - kNumberOfMonthsVisible + 12;
    var kScrollSleep = 50;  // How long between steps while scrolling.

    this.getCurrentMonthOffset = function() {
      return cursor;
    };

    function draw() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      var x = -scroll_cursor * kPixelsPerMonth + width_offset;
      for (var i = 0; i < kNumberOfMonths; ++i) {
        if (i % 12 === 0) {
          ctx.fillText(kStartYear + (i/12), x+13, kLineBottom+9);
        }
        if (i === cursor) {
          ctx.save();
          //ctx.fillStyle = '#A38566';
          ctx.fillStyle = '#B29980';
          var highlight_width = 49;
          // Special case the last year so we don't get a faded end edge.
          if (i + 12 === kNumberOfMonths) highlight_width = 48;
          ctx.fillRect(x, kLineBottom, highlight_width, -10);
          ctx.restore();
        }
        var height = 3;
        var dh = 0;
        if (i % 6 === 0) height = 6;
        if (i % 12 === 0) { height = 11; dh = 2 }
        ctx.fillRect(x, kLineBottom+dh, 1, -height);
        x += kPixelsPerMonth;
      }

      // Clear the margins.  Easier than clipping.  Fade the edges.
      var imgdata = ctx.getImageData(width_offset-3, 0, 3, canvas.height);
      var data = imgdata.data;
      for (var y = 0; y < imgdata.height; ++y) {
        data[(y * imgdata.width + 0) * 4 + 3] *= 0.2;
        data[(y * imgdata.width + 1) * 4 + 3] *= 0.4;
        data[(y * imgdata.width + 2) * 4 + 3] *= 0.7;
      }
      ctx.putImageData(imgdata, width_offset-3, 0, 0, 0,
                       imgdata.width, imgdata.height);

      var imgdata = ctx.getImageData(width+width_offset, 0, 3, canvas.height);
      var data = imgdata.data;
      for (var y = 0; y < imgdata.height; ++y) {
        data[(y * imgdata.width + 0) * 4 + 3] *= 0.7;
        data[(y * imgdata.width + 1) * 4 + 3] *= 0.4;
        data[(y * imgdata.width + 2) * 4 + 3] *= 0.2;
      }
      ctx.putImageData(imgdata, width+width_offset, 0, 0, 0,
                       imgdata.width, imgdata.height);

      ctx.clearRect(0, 0, width_offset-3, canvas.height);
      ctx.clearRect(width + width_offset+3, 0, width_offset-3, canvas.height);
    }

    draw();

    var mc = new PreGL.MouseCatcher(canvas);
    var mdx = 0;
    // Hit test
    mc.setDragFilter(function(x, y) {
      // if (window.console) window.console.log('x: ' + x);
      var sc = cursor - scroll_cursor;
      // if (window.console) window.console.log('sc: ' + sc);
      x -= width_offset;  // Adjust for margins.
      if (x >= sc * kPixelsPerMonth && x < (sc + 12) * kPixelsPerMonth) {
        // if (window.console) window.console.log('hit');
        return true;
      }
      return false;
    });
    function processDrag(dx, dy) {
      mdx += dx;
      var dirty = false;
      if (Math.abs(mdx) >= kPixelsPerMonth) {
        var dm = (mdx / kPixelsPerMonth) >> 0;
        cursor = PreGL.clamp(cursor + dm, 0, kNumberOfMonths - 12);
        mdx -= dm * kPixelsPerMonth;
        dirty = true;
      }
      // Scroll
      if (scroll_cursor + kNumberOfMonthsVisible < kNumberOfMonths &&
          (cursor - scroll_cursor + 12) * kPixelsPerMonth + kScrollM >= width) {
        scroll_cursor += 1;
        if (mc.state.down && cursor + 12 < kNumberOfMonths) cursor += 1;
        setTimeout(function() { processDrag(0, 0); }, kScrollSleep);
        dirty = true;
      }
      if (scroll_cursor != 0 &&
          (cursor - scroll_cursor) * kPixelsPerMonth - kScrollM <= 0) {
        scroll_cursor -= 1;
        if (mc.state.down && cursor > 0) cursor -= 1;
        setTimeout(function() { processDrag(0, 0); }, kScrollSleep);
        dirty = true;
      }
      if (dirty) draw();
    }
    mc.setDragHandler(processDrag);
  }    
  
  function buildCubeMapFromResources(gl, resources, prefix) {
    var cubeMap = gl.createTexture();
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_CUBE_MAP, cubeMap);

    var cubemap_map = [
      gl.TEXTURE_CUBE_MAP_POSITIVE_X, prefix + '_posx',
      gl.TEXTURE_CUBE_MAP_NEGATIVE_X, prefix + '_negx',
      gl.TEXTURE_CUBE_MAP_POSITIVE_Y, prefix + '_posy',
      gl.TEXTURE_CUBE_MAP_NEGATIVE_Y, prefix + '_negy',
      gl.TEXTURE_CUBE_MAP_POSITIVE_Z, prefix + '_posz',
      gl.TEXTURE_CUBE_MAP_NEGATIVE_Z, prefix + '_negz'
    ];
    for (var i = 0, il = cubemap_map.length; i < il; i += 2) {
      gl.texImage2D(cubemap_map[i], 0, gl.RGBA, gl.RGBA,
                    gl.UNSIGNED_BYTE, resources[cubemap_map[i+1]]);
    }
    // Bilinear texture filtering.
    gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

    return cubeMap;
  }    
  

  function Slider(canvas, opts) {
    var width = canvas.width, height = canvas.height;
    var ctx = canvas.getContext('2d');

    var value = 0;
    var value_step = 1 / width;  // Size to step value per pixel slide.
    var color1 = opts.color1;  // Color drawn from begin to value.
    var color2 = opts.color2;  // Color drawn from value to end.

    function getValue() {
      return value;
    }

    var update_handler = null;
    this.setUpdateHandler = function(handler) {
      update_handler = handler;
    };

    function setValue(v) {
      value = PreGL.clamp(v, 0, 1);
      draw();
      if (update_handler !== null) update_handler(value);
    }

    this.getValue = getValue;
    this.setValue = setValue;

    function draw() {
      ctx.clearRect(0, 0, width, height);
      ctx.strokeStyle = '#ccc';
      ctx.lineWidth = 2;
      ctx.strokeRect(0, 0, width, height);
      if (color1 !== null) {
        ctx.fillStyle = color1;
        ctx.fillRect(0, 0, width * value, height);
      }
      if (color2 !== null) {
        ctx.fillStyle = color2;
        ctx.fillRect(width * value, 0, width, height);
      }
      // Stupid strokeRect has darker pixels at the 4 corners.
      //ctx.beginPath();
      //ctx.moveTo(0, 0); ctx.lineTo(width, 0);
      //ctx.lineTo(width, height); ctx.lineTo(0, height);
      //ctx.closePath(); ctx.stroke();
      // Line width fixes it.
    }
    var mouse_catcher = new PreGL.MouseCatcher(canvas);

    function updateAtRelativeXY(rx, ry) {
      setValue(value_step * rx);
    }

    // Abuse the drag filter to get down events.
    mouse_catcher.setDragFilter(function(rx, ry) {
      updateAtRelativeXY(rx, ry);
      return true;  // Always a drag.
    });
    mouse_catcher.setDragHandler(function(dx, dy, rx, ry) {
      updateAtRelativeXY(rx, ry);
    });
    draw();
  }

  function Timer() {            
    var prevTime = new Date().getTime(); 
    var deltaTime = 0;  
    var totalTime = 0;
    
    this.update = function() {
      var currTime = new Date().getTime();
      deltaTime = (currTime - prevTime)/1000;
      prevTime = currTime;   
      totalTime += deltaTime;
    } 
    
    this.getDeltaTime = function() {
      return deltaTime;
    }                  
    
    this.getTotalTime = function() {
      return totalTime;
    }
  }   
  
  return {
    JSONManager: JSONManager,
    Timeline: Timeline,    
    Slider: Slider,
    Timer: Timer,
    buildCubeMapFromResources : buildCubeMapFromResources
  };
})();
