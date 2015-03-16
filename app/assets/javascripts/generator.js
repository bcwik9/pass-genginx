// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(document).ready(function() {
    var max_fields      = 99; //maximum input boxes allowed
    var wrapper         = $(".multi-field-wrapper"); //Fields wrapper
    var add_button      = $(".add-field"); //Add button ID
    
    var x = 1; //initial text box count

    // add element
    $(add_button).click(function(e){ //on add input button click
        e.preventDefault();
        if(x < max_fields){ //max input box allowed
            x++; //text box increment
            $(wrapper).append(
		'<div>Github clone URL: <input type="text" name="github_repo[]" \><a href="#" class="remove_field">Remove</a><br></div>'
	    );
        }
    });
    
    // remove element
    $(wrapper).on("click",".remove_field", function(e){ //user click on remove text
        e.preventDefault(); $(this).parent('div').remove();
	x--;
    })
});
