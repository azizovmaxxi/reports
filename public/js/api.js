function APICall(call, params, callback){
	var req = {command:call,parameters:params};
	const xhr = new XMLHttpRequest();
	xhr.open('post','/api', true);
	xhr.setRequestHeader('Content-Type','application/json');
	xhr.onreadystatechange = function(){
		if((xhr.readyState===4)&&(callback)) callback(xhr.responseText);
	};
	xhr.send(JSON.stringify(req));
}