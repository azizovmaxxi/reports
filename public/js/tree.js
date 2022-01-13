$(document).ready(function(){

  /**TODO: Create treeview */
 var checkTree =  {
    mounting: function(currentElement, nodes){
    var ul, li, checkbox, label, span;
    ul = document.createElement("ul");  
    for(let p in nodes){
      li = document.createElement("li");  

      checkbox = document.createElement("input");
      checkbox.type = "checkbox";
      checkbox.checked = nodes[p]["flag"];
      checkbox.name = nodes[p]["name"];
      checkbox.value = nodes[p]["value"];
      checkbox.addEventListener("click",function(){        

        var li = this.parentNode;
        
        var ul = li.getElementsByTagName("ul")[0];
        
        if(ul!==undefined){
        var boxes = ul.getElementsByTagName("input");
        
        for(let i = 0; i < boxes.length; i++){
          if( boxes[i]["type"] == "checkbox" )
             boxes[i]["checked"] = this.checked;
        }
      }
        
      });
      

      li.appendChild(checkbox);

      label = document.createElement("label");
      label.htmlFor = checkbox.id;
      label.innerHTML = nodes[p]["desc"];

      li.appendChild(label);

      if(nodes[p]["nodes"]){
        span = document.createElement("span");
        span.className = "checkTree-close";
        span.onclick = function(){
        let triangle = this.className.indexOf("checkTree-open")+1;   
        this.className = triangle ? "checkTree-close":"checkTree-open";
        let ul = this.parentNode.getElementsByTagName("ul")[0];
        ul.style.display = triangle ? "none" : "block";
        }
        li.insertBefore(span, li.firstChild);
        this.mounting(li ,nodes[p]["nodes"])
      }
      
      ul.appendChild(li);
    }

    currentElement.appendChild(ul);

    },
    init: function(id, jsonObj){
      var t = document.getElementById(id);
      this.mounting(t, jsonObj.nodes);    
    }
 };

 $("#treelpu").on("click", function(){

  $("#checkTree").toggle();

  if($("#treelpu").is(":checked") && !$("#checkTree ul").is("ul"))
    {
      $.getJSON("/get_treelpu", {id: this.id},
        function success(data, status, jqXHR){
        if (data)
        {
          checkTree.init("checkTree", data);
          $("#checkTree >ul >li >ul").css("display", "none");

        }else{
          console.log("Not found");
        }
      }).fail(function (e, res) {
        console.log("error")
      });
    }
  if (!$("#treelpu").is(":checked"))
  {
      let iboxes = $("#checkTree input:checkbox:checked");
      for (let i=0; i<iboxes.length; i++)
      {
        iboxes[i]["checked"] = false;
      }
      $("#gsvname").val("");

  }});

 $("#treedoc").on("click", function(){

    $("#docTree").toggle();
  
    if($("#treedoc").is(":checked") && !$("#docTree ul").is("ul"))
      {
        $.getJSON("/get_treelpu", {id: this.id},
          function success(data, status, jqXHR){
          if (data)
          {
            checkTree.init("docTree", data);
            $("#docTree >ul >li >ul").css("display", "none");
          }else{
            console.log("Not found");
          }
        }).fail(function (e, res) {
          console.log("error")
        });
    }

    if (!$("#docTree").is(":checked"))
    {
        let iboxes = $("#docTree input:checkbox:checked");
        for (let i=0; i<iboxes.length; i++)
        {
          iboxes[i]["checked"] = false;
        }
        $("#doctorname").val("")
    }
  });

 $("#checkTree").change(function(){
   let code = [];
      $("#checkTree input:checkbox:checked").not("#treelpu").map(function(){
        code.push($(this).next().text());
      });
      $("#gsvname").val(code.join("; "));
  });
  
 $("#docTree").change(function(){
  let doc = [];
     $("#docTree input:checkbox:checked").not("#treedoc").map(function(){
      doc.push($(this).next().text());
     });
     $("#doctorname").val(doc.join("; "));
  });
});



