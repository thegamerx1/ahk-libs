function formObject(formSelector){var data={};$(formSelector).serializeArray().map(function(x){data[x.name]=x.value});return data}function setDataToForm(e,data){if(e.jquery)e=e[0];for(var property in data){var element=e.querySelector("input[name="+property+"]");if(element)element.value=data[property]}}function random(min,max){return Math.floor(Math.random()*(max-min))+min}function activate(status){$(document.body).toggleClass("active",!!status)}function removeLoader(){document.getElementById("loader").classList.add("hide")}function refreshElement(e){var parent=e.parent();var element=e.detach();parent.append(element)}function generateTemplates(){var templates=$("template");var object={};templates.each(function(){var e=$(this);object[e.attr("name")]=e});return object}jQuery.fn.reverse=[].reverse;