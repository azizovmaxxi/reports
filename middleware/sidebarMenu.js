/** Меню - список отчетов для подсчета статистических данных*/
module.exports = function(req, res, next){
  res.locals.sidebarMenu = req.session.sidebarMenu;
  next()
}