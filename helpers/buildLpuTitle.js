/** Возвращает наименование ЛПО*/
module.exports = function(lpu) {
    if(lpu.id < 0){ return `${lpu.text} ${lpu.parent_name}`}
    if(lpu.id === lpu.parent_id){ return `${lpu.text}`}
    return `${lpu.text}`
}