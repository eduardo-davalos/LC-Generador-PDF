({
    //accion inicial al cargar el lighning component
    doInit: function (component,event,helper)
    {
        //manda a llamar obtenFormatosCompatibles para obtener las plantillas de formatos
        helper.obtenFormatosCompatibles(component);
    },

    //accion al dar click en Generar Formato
    generarFormato: function(component, event, helper) {
        //Manda a llamar generarFormato, genera el pdf y lo guarda
        helper.generarFormato(component, event);
    }
})