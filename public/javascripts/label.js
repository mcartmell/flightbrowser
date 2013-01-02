// Define the overlay, derived from google.maps.OverlayView
function Label(opt_options) {
 // Initialization
 this.setValues(opt_options);

 // Label specific
 var span = this.span_ = document.createElement('span');
 span.style.cssText = 'position: relative; left: -50%; top: -8px; ' +
                      'white-space: nowrap; padding: 0px; background-color: white; text-shadow: 1px 1px 1px #fff; border-radius: 2em; padding: 2px; border: 1px solid #ccc';

 var div = this.div_ = document.createElement('div');
 div.appendChild(span);
 div.style.cssText = 'position: absolute; display: none';
 // Apply style values defined in the labelStyle parameter:
 labelStyle = this.get("labelStyle");
 for (i in labelStyle) {
   if (labelStyle.hasOwnProperty(i)) {
     span.style[i] = labelStyle[i];
   }
 }
};
Label.prototype = new google.maps.OverlayView;

// Implement onAdd
Label.prototype.onAdd = function() {
 var pane = this.getPanes().overlayMouseTarget;
 pane.appendChild(this.div_);

 // Ensures the label is redrawn if the text or position is changed.
 var me = this;
 this.listeners_ = [
   google.maps.event.addListener(this, 'position_changed',
       function() { me.draw(); }),
   google.maps.event.addListener(this, 'text_changed',
       function() { me.draw(); }),
   google.maps.event.addDomListener(this.div_, 'mouseover', function() {
    google.maps.event.trigger(me, 'mouseover');
   }),
   google.maps.event.addDomListener(this.div_, 'click', function() {
    google.maps.event.trigger(me, 'click');
   })
 ];
};

// Implement onRemove
Label.prototype.onRemove = function() {
 this.div_.parentNode.removeChild(this.div_);

 // Label is removed from the map, stop updating its position/text.
 for (var i = 0, I = this.listeners_.length; i < I; ++i) {
   google.maps.event.removeListener(this.listeners_[i]);
 }
};

// Implement draw
Label.prototype.draw = function() {
 var projection = this.getProjection();
 var position = projection.fromLatLngToDivPixel(this.get('position'));

 var div = this.div_;
 div.style.left = position.x + 'px';
 div.style.top = position.y + 'px';
 div.style.display = 'block';

 this.span_.innerHTML = this.get('text').toString();
};
