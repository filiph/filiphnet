
/* filiph.net JavaScript file */

window.onload = function() {

	showInfo = new fx.Height('info', {duration: 400});
	showInfo.hide();
	showBlog = new fx.Height('blog', {duration: 400});
	showBlog.hide();
	showAudio = new fx.Height('audio', {duration: 400});
	showAudio.hide();
	showVideo = new fx.Height('video', {duration: 400});
	showVideo.hide();
	
	showFootnote = new fx.Height('footnote', {duration: 200});
	showFootnote.hide();

	// inicializujeme pozpatku, jinak by Java hlasila, ze nezna "nasledujici" funkci
	showVideoDivider = new fx.Opacity('videoDivider', {duration: 200, onComplete:function() {showFootnote.toggle();}});
	showVideoDivider.hide();		
	showAudioDivider = new fx.Opacity('audioDivider', {duration: 200, onComplete:function() {showVideoDivider.toggle();}});
	showAudioDivider.hide();
	showBlogDivider = new fx.Opacity('blogDivider', {duration: 200, onComplete:function() {showAudioDivider.toggle();}});
	showBlogDivider.hide();
	showInfoDivider = new fx.Opacity('infoDivider', {duration: 200, onComplete:function() {showBlogDivider.toggle();}});
	showInfoDivider.hide();
	showVideoButton = new fx.Opacity('videoButton', {duration: 200, onComplete:function() {showInfoDivider.toggle();}});
	showVideoButton.hide();
	showAudioButton = new fx.Opacity('audioButton', {duration: 200, onComplete: function() {showVideoButton.toggle();}});
	showAudioButton.hide();
	showBlogButton = new fx.Opacity('blogButton', {duration: 200, onComplete: function() {showAudioButton.toggle();}});
	showBlogButton.hide();
	showInfoButton = new fx.Opacity('infoButton', {duration: 200, onComplete: function() {showBlogButton.toggle();}});
	showInfoButton.hide();

	hideBlankSpace = new fx.Height('blankSpace', {duration: 500, onComplete: function() {showInfoButton.toggle();}});
	hideBlankSpace.toggle();

	//showInfoButton.toggle();
}
