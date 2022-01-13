/**
 *Initialization FormViewModel 
 **/
const builLpuTitle = require('../helpers/buildLpuTitle');

var FormViewModel = class {
   constructor(data){
     this.data=data;
   }

   getViewModel(){
    this.lpuTitle = builLpuTitle(JSON.parse(this.data.lpu_id || "{}"));
    this.sdate = this.data.sdate;
    this.edate = this.data.edate;
    this.lpuId = (typeof(this.data.lpu_id)!=='undefined')?JSON.parse(this.data.lpu_id):null;
    this.doctor = (typeof(this.data.doctor_id)!=='undefined')?JSON.parse(this.data.doctor_id):null;
    this.doctorId = (typeof(this.data.doctor_id)!=='undefined')?(JSON.parse(this.data.doctor_id)).id:null;
    this.rpt = this.data.rpt28;
    return this;  
   }

 }

module.exports=FormViewModel;