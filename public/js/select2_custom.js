$( document ).ready(function() {

  function buildSelect2Items(data, terType){
    if(terType === 'lpu_id'){
      return data.map((item) => {
        return {
          text: item.name,
          children: item.children
        }
      })
    } else {
      return data.map((item) => {
        return {
          id: item.id,
          text: item.name,
        }
      })
    }
  }

  let terID = {ter2_id: null, ter3_id: null};
  let select2List = {};

  function disableSelect2(selectTagID){
    if(selectTagID === 'lpu_id'){
      let selectDoctor = $("#doctor_id");
      selectDoctor.val(null).trigger("change");
      selectDoctor.prop("disabled", true);

      let selectPatient = $("#patient_id");
      selectPatient.val(null).trigger("change");
      selectPatient.prop("disabled", true);
    }
  }

  function enableSelect2(selectTagID){
    if(selectTagID === 'lpu_id'){
      $("#doctor_id").prop("disabled", false);
      $("#patient_id").prop("disabled", false);
    }
    
    if (selectTagID === 'ter2_id') {
      let selectLpu = $("#lpu_id");
      selectLpu.val(null).trigger("change");
    }
  }

  $(".ter-select").each(function () {
    let selectTagID = this.id;

    $(this).on('select2:select', function (e) {
      terID[selectTagID] = e.params.data.id;
      enableSelect2(selectTagID);
    });

    $(this).on('select2:unselect', function (e) {
      terID[selectTagID] = null;
      disableSelect2(selectTagID);
    });

    select2List[this.id] = $(this).select2({
      allowClear: true,
      placeholder : "",
      ajax: {
        url: '/ter_select',
        delay: 800,
        dataType: 'json',
        data: function(params){
          return {
            terType: selectTagID,
            id_or_name: params.term,
            ...terID
          }
        },
        processResults: function (data) {
          return {
            results: buildSelect2Items(data, selectTagID)
          };
        },
      },
    });
  });

  // START init Select2 for DoctorSelect
  select2List['doctor_id'] = $("#doctor_id").select2({
    allowClear: true,
    placeholder : "ФИО врача",
    ajax: {
      url: '/get_doctor',
      delay: 800,
      dataType: 'json',
      data: function(params){
        let lpu = $("#lpu_id option:selected").val();
        return {
          doctor_name: params.term,
          lpu_id: lpu
        }
      },
      processResults: function (data) {
        return {
          results: data.map((item) => {
            return {
              id: JSON.stringify(item),
              text: item.name_format,
            }
          })
        };
      }
    }
  });
  // END init Select2 for DoctorSelect

  // START init Select2 for PostCode
  select2List['post_code'] = $("#post_code").select2({
    allowClear: true,
    placeholder : "Код должности",
    ajax: {
      url: '/get_post_code',
      delay: 800,
      dataType: 'json',
      data: function(params){
        return {
          code_or_name: params.term
        }
      },
      processResults: function (data) {
        return {
          results: data.map((item) => {
            return {
              id: JSON.stringify(item),
              text: `${item.code} |  ${item.name}`,
            }
          })
        };
      }
    }
  });
  // END init Select2 for PostCode

  // START init Select2 for ICD10
  $(".icd10-select").each(function () {

    // select2List['doctor_id'] = $(this).select2({
    $(this).select2({
      allowClear: true,
      placeholder: "МКБ-10",
      ajax: {
        url: '/get_icd10',
        delay: 800,
        dataType: 'json',
        data: function(params){
          return {
            icd10: params.term
          }
        },
        processResults: function (data) {
          return {
            results: data.map((item) => {
              return {
                id: item.icd10,
                text: `${item.icd10} |  ${item.disease}`,
              }
            })
          };
        }
      }
    });
  });
  // END init Select2 for ICD10

  // START init Select2 for PatientSelect
  select2List['patient_id'] = $("#patient_id").select2({
    allowClear: true,
    placeholder : "ФИО пациента",
    ajax: {
      url: '/get_patient',
      delay: 800,
      dataType: 'json',
      data: function(params){
        let lpu = $("#lpu_id option:selected").val();
        return {
          patient_name: params.term,
          lpu_id: lpu
        }
      },
      processResults: function (data) {
        return {
          results: data.map((item) => {
            return {
              id: JSON.stringify(item),
              text: `${item.full_name} (${item.birth_day})`,
            }
          })
        };
      }
    }
  });
  // END init Select2 for PatientSelect

  // START init Select2 for vistyp_code
  $(".vistyp_code-select").each(function () {

    $(this).select2({
      allowClear: true,
      placeholder: "Код посещения",
      ajax: {
        url: '/get_visittype',
        delay: 800,
        dataType: 'json',
        data: function(params){
          return {
            visittype: params.term
          }
        },
        processResults: function (data) {
          return {
            results: data.map((item) => {
              return {
                id: item.code,
                text: `${item.code} |  ${item.full_name}`,
              }
            })
          };
        }
      }
    });
  });
  // END init Select2 for vistyp_code

  //Get list trauma type
  $(".traumtype-select").each(function (){
    $(this).select2({
      allowClear: true,
      placeholder: "Код травмы",
      ajax: {
        url: '/get_traumatype',
        dataType: 'json',
        data: function(params){
          return {
            traumtype: params.term
          }
        },
        processResults: function(data){
          return {
            results: data.map((item)=>{
              return {
                    id: item.code,
                    text: `${item.code} - ${item.full_name}`
              }
            })
          }
        }
      }
    });
  });
});
