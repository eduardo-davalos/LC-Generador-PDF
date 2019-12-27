({
    //Accion para obtener la lista de plantillas de formatos de impresión
    obtenFormatosCompatibles:function(component)
    {
        //Hace referencia al metodo obtenFormatosImpresion apex
        var action = component.get("c.obtenFormatosImpresion");
        //Asigna los parametros, el id del registro actual
        action.setParams({
            idRegistro: component.get("v.recordId"),
        });
        //Inicia el llamado
        action.setCallback(this, function(response) {
            //se obtiene estatus de la llamada
            var state = response.getState();
            //si fue exitoso
            if (state == 'SUCCESS') 
            {
                //se agregan los formatos a la lista picklist, y se selecciona el primero 
                var formatosDisponibles = response.getReturnValue();
                component.set("v.formatosDisponibles",formatosDisponibles);
                component.set("v.formatoSeleccionado",formatosDisponibles[0].Id);
            } 
        });
        $A.enqueueAction(action);
    },

    //Accion para generar el pdf y guardarlo en el registro
    generarFormato: function(component, event) {
        //Se inicia el spinner, para saber que esta cargando
        component.set("v.showSpinner", true);
        //Se referencia generarFormatoImpresion apex 
        var action = component.get("c.generarFormatoImpresion");
        //se agregan los parametros, el registro actual, y el formato deseado.
        action.setParams({
            idRegistro: component.get("v.recordId"),
            idFormato:component.get("v.formatoSeleccionado")
        });
        //Se hace el llamado al metodo
        action.setCallback(this, function(response) {
            //obtenemos el estaus de la llamada
            var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");
            //si fue exitoso
            if (state == 'SUCCESS') {
                //obtenemos el resultado del metodo
                var rtnValue = response.getReturnValue();
                //Apagamos el spinner
                component.set("v.showSpinner", false);
                //Si la respuesta fue Éxito
                if (rtnValue == 'Éxito') {
                    //actualizamos la pagina
                    $A.get('e.force:refreshView').fire();
                    component.set("v.refrescaComponente", true);
                }
                //si no fue exitoso 
                else {
                    //mandamos el error
                    toastEvent.setParams({
                        "title": "Error!",
                        "type": "error",
                        "message": rtnValue
                    });
                    toastEvent.fire();
                    //Apagamos spinner
                    component.set("v.showSpinner", false);
                }
            }
            //si no fue un llamado exitoso regresamos error. 
            else {
                toastEvent.setParams({
                    "title": "Error!",
                    "type": "error",
                    "message": "Ocurrio un error al generar el formato."
                });
                toastEvent.fire();
                //apagamos spinner
                component.set("v.showSpinner", false);
            }
        });
        $A.enqueueAction(action);

    }
})