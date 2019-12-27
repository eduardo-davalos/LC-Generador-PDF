/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Clase TEST de Salesforce para probar la clase GeneracionFormatoImpresionController.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Eduardo Davalos   <eduardo.davalos@cloudco.com.mx>
* @version        1.0
* @created        27-12-2019
* @modified       27-12-2019
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v 1.0           eduardo.davalos@cloudco.com.mx
* 27-12-2019      Generación de la clase.
				   setup()
				   testFuncionalidadCorrecta()
				   testErrores()
* ──────────────────────────────────────────────────────────────────────────────────────────────────┘
**/
@isTest
private class GeneracionFormatoImpresionTest {
    //Setup del trigger, para crear objetos necesarios.
    @testSetup static void setup()
    {        
        //Iniciamos el test insertando un nuevo formato de impresión
        FormatosImpresion__c nuevoFormato = new FormatosImpresion__c();
        nuevoFormato.Name = 'Nombre';
        nuevoFormato.ContenidoFormato__c = 'Titulo {{Name}} Correo: {{Email__c}} Propietario: {{Owner.Name}} [[LOOP [[Task-WhatId]] Tarea asignada Asunto: {{Subject}} LOOP]]';
        nuevoFormato.ObjetoRelacionado__c = 'Account';
        insert nuevoFormato;
		//Insertamos una cuenta
        Account nuevaCuenta = new Account();
        nuevaCuenta.Name = 'test';
        nuevaCuenta.Email__c = 'email@email.com';
        insert nuevaCuenta;

    }

    //Metodo de prueba para el caso de que todo sea correcto
    @isTest static void testFuncionalidadCorrecta()
    {
        //obtenemos la cuenta
        id idCuenta = [Select id from Account limit 1].id;
        //iniciamos la prueba
        test.startTest();
        //obtenemos los formatos disponibles para la account con el metodo obtenFormatosImpresion
        List<FormatosImpresion__c> formatos = GeneracionFormatoImpresionController.obtenFormatosImpresion(idCuenta);
        //Hacemos el assert para validar el metodo anterior y este generarFormatoImpresion
        System.assertEquals('Éxito', GeneracionFormatoImpresionController.generarFormatoImpresion(idCuenta, formatos[0].id));
        test.stopTest();
    }
    
    //Metodo para probar las lineas de errores
    @isTest static void testErrores()
    {
        //obtnemos la cuenta
        id idCuenta = [Select id from Account limit 1].id;
        //iniciamos el test
        test.startTest();
        //obtenemos los formatos disponibles para la account con el metodo obtenFormatosImpresion
        List<FormatosImpresion__c> formatos = GeneracionFormatoImpresionController.obtenFormatosImpresion(idCuenta);
        //recoremos los formatos disponibles y lo cambiamos a un formato que provocara un errror
        for(FormatosImpresion__c formato : formatos)
        {
            formato.ContenidoFormato__c = '{{Error}}';
        }
        update formatos;
        //probamos con el formato error
        String resultadoError = GeneracionFormatoImpresionController.generarFormatoImpresion(idCuenta, formatos[0].id);
        //Validamos que tenga un error de generar formato
        System.assertEquals(TRUE, resultadoError.startsWith('Ocurrio un error al generar el formato, favor de contactar a su administrador.:'));
        //probamos sin formato
        resultadoError = GeneracionFormatoImpresionController.generarFormatoImpresion(null, null);
        //Validamos que recibimos un error de que no e encontro la plantilla
        System.assertEquals(TRUE, resultadoError == 'No se encontro la plantilla  del formato.');
        //probamos con un id incorrecto.
        GeneracionFormatoImpresionController.getObjetoRelacionado('identificador');
        test.stopTest();
    }
}