/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Clase de Salesforce para gestionar el componente GeneacionFormatoImpresion.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Eduardo Davalos   <eduardo.davalos@cloudco.com.mx>
* @version        1.0
* @created        26-12-2019
* @modified       26-12-2019
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v 1.0           eduardo.davalos@cloudco.com.mx
* 26-12-2019      Generación de la clase.
                    -getObjetoRelacionado
                    -generarFormatoImpresion
                    -obtenerFormatoImpresion
                    -obtenValoresVariables
                    -obtenFormatosImpresion
                    -adjuntaPDF
* ──────────────────────────────────────────────────────────────────────────────────────────────────┘
**/
public with sharing class GeneracionFormatoImpresionController {
    
    /*
    Metodo para saber cual es el objeto del registro actual
    Recibe un string, con el id del registro
    Devuelve un string con el nombre del objeto
     */
    public static string getObjetoRelacionado(String identificador){
        // Se obtienen los primeros 3 digitos del id del registro
        String idPrefijo = identificador.substring(0,3);
        //recoremos los objetos de la instancia
        for (Schema.SObjectType obj: Schema.getGlobalDescribe().values()) {
            //obtenemos los 3 primeros digitos del objeto actual
            String prefijoObjeto = obj.getDescribe().getKeyPrefix();
            //comparamos los prefijos del objeto actual, con el nuestro
            if (prefijoObjeto == idPrefijo) {
                //si coinciden devolvemos el nombre
                return obj.getDescribe().getName();
            }
        }
        //si no se encontro objeto devolvemos null
        return null;
    }

    /*
    Metodo Aura para generar un archivo pdf en base al registro actual
    Recibe 2 ids, uno del registro actual, y uno de la plantilla del formato de impresion
    Devuelve un string con el resultado del metodo.
     */
    @AuraEnabled
    public static String generarFormatoImpresion(id idRegistro, id idFormato) 
    {
        //Se manda a llamar obtenerFormatoImpresion, y recibimos un FormatosImpresion__c
        FormatosImpresion__c formatoImpresionDefault =  obtenerFormatoImpresion(idFormato);
        // nuestro FormatosImpresion__c es diferente de null
        if(formatoImpresionDefault != null)
        {
            //intentamos generar el pdf
            try
            {
                String parrafoGenerado = obtenValoresRegistrosHijos(formatoImpresionDefault.ContenidoFormato__c, idRegistro);
                //Se manda a llamar obtenValoresVariables, recibimos el cuerpo del pdf
                parrafoGenerado = obtenValoresVariables(parrafoGenerado, idRegistro, formatoImpresionDefault.ObjetoRelacionado__c, 'Id');
                //si hubo null, los quitamos
                parrafoGenerado = parrafoGenerado.replaceAll('null','');  
                //llamamos adjuntaPDF para guardar el file
                adjuntaPDF(idRegistro, Blob.toPdf(parrafoGenerado), formatoImpresionDefault.Name);
                //devolvemos el exito
                return 'Éxito';
            }
            //si hubo un problema
            catch (Exception ex)
            {
                //devolvemos el error
                system.debug('Error:: ' +ex.getMessage()+' '+ex.getStackTraceString());
                return 'Ocurrio un error al generar el formato, favor de contactar a su administrador.: '+ex.getMessage() ;
            }
        }
        //devolvemos el error
        return 'No se encontro la plantilla  del formato.';
    }

    /*
    Metodo  para obtener la plantilla del formato de impresion deseado
    Recibe un id del registro FormatosImpresion__c
    Devuelve un FormatosImpresion__c.
     */
    public static FormatosImpresion__c obtenerFormatoImpresion(Id idRegistro)
    {
        //Buscamos el formato de impresión con el id brindado
        List<FormatosImpresion__c> formatosImpresion = [Select id,Name,ContenidoFormato__c ,ObjetoRelacionado__c
                                                        From FormatosImpresion__c 
                                                        Where id =: idRegistro order by name asc];

        //si existe, lo devolvemos, si no devolvemos null                             
        return formatosImpresion.isEmpty() ? null : formatosImpresion[0];
    }

    /*
    Metodo  para hacer el remplace del parrafo LOOP
    Este parrafo son los valores de los registros hijos relacionados al registro
    Recibe el parrafo completo, recibe el id del registro donde obtenedra la relacion
    Devuelve un string con el parrafo nuevo y listo.
     */
    public static String obtenValoresRegistrosHijos(String parrafo, id idRegistro)
    {
        //Contamos el numero de parrafos donde se necesita realizar conversión
        Integer contadorParrafosLoop = parrafo.countMatches('[[LOOP');
        //recoremos los parrafos
        for (Integer i = 0; i < contadorParrafosLoop; i++) 
        {
            //Obtenemos el parrafo de iteración Original, para reemplazarlo mas tarde
            String parrafoIteracionOriginal = parrafo.substringBetween('[[LOOP','LOOP]]');
            //Obtenemos el objeto que usaremos y su campo relacionado
            String textoRelacion = parrafoIteracionOriginal.substringBetween('[[',']]');
            if(textoRelacion!=null)
            {
                //Removemos el objeto que usaremos y su campo relacionado del formato final
                String parrafoCambiar = parrafoIteracionOriginal.remove('[['+textoRelacion+']]');
                //los separamos para su uso
                String[] objetoRelacion = textoRelacion.split('-');
                //Mandamos a llamar la generación de parrafos, por cada parrafo diferente
                //Este metodo ejecuta un query, y esta dentro de un for, sin embargo, no es el mismo query
                //Es un query dinamico,y puede ser para uno o mas objetos diferentes, por lo que es necesario tenerlo
                //dentro de este loop for
                String parrafoGenerado = obtenValoresVariables(parrafoCambiar, idRegistro, objetoRelacion[0], objetoRelacion[1]);
                //Remplazamos el parrafo inservible por el nuevo
                parrafo = parrafo.replace('[[LOOP'+parrafoIteracionOriginal+'LOOP]]',parrafoGenerado);

            }
            //Mandamos a hacer la conversion de parrafos y variables.
        }
        return parrafo;

    }

    /*
    Metodo  para hacer el remplace de las variables de la plantilla con las variables reales
    Recibe el parrafo a cambiar, recibe el id del registro donde obtenedra variables, y su objeto
    Devuelve un string con el parrafo nuevo y listo.
     */
    public static String obtenValoresVariables(String parrafo, id idRegistro, string objetoRelacionado, string campoBusquedaId)
    {
        //Contamos cuantas variables debemos remplazar
        Integer contadorVariables = parrafo.countMatches('{{');
        //iniciamos un set para guardar las variables y hacerles query
        Set<string> variablesUnicas = new Set<String>();
        //recoremos el numero de variables 
        for (Integer i = 0; i < contadorVariables; i++) 
        {
            //por cada variable la agregamos al set
            String variableTemporal = parrafo.substringBetween('{{','}}');
            variablesUnicas.add(variableTemporal);
            //por cada variable la reemplazamos a solo un {}, para no repetirla.
            parrafo = parrafo.replace('{{'+variableTemporal+'}}','{'+variableTemporal+'}');  

        }
        //Iniciamos a formar el query cn las variables en el set
        String variablesQuery = 'Id';
        for (String variable : variablesUnicas) 
        {
            //recoremos el set y por cada variable le agregamos coma
            variablesQuery+=','+variable;
        }
        //se complementa el query dinamico y se ejecuta 
        String queryDinamico = 'SELECT '+variablesQuery+' FROM '+objetoRelacionado+' where '+campoBusquedaId+' =\''+idRegistro+'\' ';
        List<SObject> registrosEncontrados = Database.query(queryDinamico);

        String parrafoCompleto ='';
        //Se recore la lista de registros obtenidos en el query
        for(SObject registroEncontrado: registrosEncontrados)
        {
            //se conjuntan en un parrafo mas grande
            parrafoCompleto+=convierteVariables(parrafo,registroEncontrado, contadorVariables);
        }
        //se genera el nuevo parrafo
        parrafo = parrafoCompleto;
        
        //devolvemos el parrafo.
        return parrafo;
    }

    public static String convierteVariables(String parrafo, SObject registroEncontrado, Integer contadorVariables) 
    {
        //Si e query devolvio un registro          
        if(registroEncontrado!=null)
        {
            //recoremos el numero de variables
            for (Integer i = 0; i < contadorVariables; i++) 
            {
                //y hacemos el replace de cada variable involucrada con la variable de nuestro registro.
                String variableTemporal = parrafo.substringBetween('{','}');
                //Revisamos se la variable contiene una relacion lookup/master
                if(variableTemporal.contains('.'))
                {
                    //si si contiene, obtenemos el valor del campo de su relacion
                    List<String> objetoCampo = variableTemporal.split('\\.');
                    parrafo = parrafo.replace('{'+variableTemporal+'}',''+registroEncontrado.getSobject(objetoCampo[0]).get(objetoCampo[1]));  
                }
                //si no solo obtenemos el valor del campo actual
                else {
                    parrafo = parrafo.replace('{'+variableTemporal+'}',''+registroEncontrado.get(variableTemporal));  
                }
            }
        }
        return parrafo;
    }

    /*
    Metodo  Aura para obtener las plantillas de formato del objeto actual
    Recibe el id del registro actual
    Devuelve una lista de  FormatosImpresion__c.
     */
    @AuraEnabled
    public static List<FormatosImpresion__c> obtenFormatosImpresion(id idRegistro) 
    {
        //se obtiene el nombre del objeto relacinado
        String objetoRelacionado = getObjetoRelacionado(idRegistro);
        //se devuelve la lista, buscando las plantillas del objeto elegido.
        return [Select id, Name, TituloDelFormato__c from FormatosImpresion__c where ObjetoRelacionado__c =: objetoRelacionado];
    }
    

    /*
    Metodo para guardar el nuevo pdf en el registro relaionado
    Recibe el id del registro actual, el blob del pdf, y el nombre del documento
     */
    public static void adjuntaPDF(Id idRegistro, Blob paginaPDF, String nombreDocumento){
        
        //Variable del archivo de SF
        ContentVersion archivoPDF = new ContentVersion();
        //Asignación de nombre, contenido, versión última, ruta y tipo
        archivoPDF.Title = nombreDocumento+' ' + DateTime.now() + '.pdf';
        archivoPDF.VersionData = paginaPDF;
        archivoPDF.IsMajorVersion = true;
        archivoPDF.PathOnClient = archivoPDF.Title;
        //Inserta el archivo
        insert archivoPDF;
        //Variable del id del contenedor del archivo de SF para relacionarlo con el objeto
        Id contenedorArchivoId = [Select ContentDocumentId from ContentVersion where Id =: archivoPDF.Id].ContentDocumentId;
        //Enlace al objeto que se desea aparezca como adjunto
        ContentDocumentLink enlace = new ContentDocumentLink();
        //Asignación del id del contenedor, id del objeto, tipo que se comparte
        enlace.ContentDocumentId = contenedorArchivoId;
        enlace.LinkedEntityId = idRegistro;
        enlace.ShareType = 'I';
        //Inserta el enlace
        insert enlace;
    }
}