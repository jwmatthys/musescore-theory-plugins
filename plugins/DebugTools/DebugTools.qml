//==============================================
//
//  Ce programme est un logiciel libre: vous pouvez le redistribuer/modifier
//  sous les conditions de la licence GNU (Version 3 ou ultérieure)
//
//  Nous espèrons que ce programme vous sera utile,
//  mais il est fourni SANS GARANTIE.   Voir la licence
//  GNU pour plus de détails.
//
//  Pour voir la licence GNU :
//  voir le site  <http://www.gnu.org/licenses/>.
//
//  Attention : la version de Musescore 4.0 (ou plus) est requise
//  2023 Dominique Verrière
//==============================================

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2

import FileIO 3.0

Item {
    id: debugTools
    property string pluginName: "" // to be passed from caller
    property string logContent: ""

    property string versionTools: "1.01"
    // 1.01 Version initiale

    FileIO
    {// On instancie un fichier pour le log
        id: fhFichierLog
        source: ""
        onError: console.log(msg)
     }


    Component.onCompleted:
    {// Au chargement complet du plugin
        var logFileName ;
        if (pluginName && pluginName !== "")
        {
            logFileName = fhFichierLog.homePath() + "/Documents/MuseScore4/Plugins/" + pluginName + "/" + pluginName + "log.txt";
            fhFichierLog.source = logFileName;
            appendLog("Démarrage " + getDateSysteme());
        }

    }

    Component.onDestruction:
    {// Au déchargement du plugin
        if (fhFichierLog.source === "")
            return;
        appendLog("Arrêt " + getDateSysteme());
        writeLogFile();
    }



    function appendLog(chaine)
    {// Ajouter une chaine au log
        logContent = logContent + chaine + "\n";
    }


    function writeLogFile(clearLog = false)
    {// Ecrire le log avant de quitter (ou au besoin)
        fhFichierLog.write(logContent);
        if (clearLog)
            logContent = "";
    }


    function getDateSysteme()
    {// Rend une chaine qui contient date et heure système
        var retour = Qt.formatDateTime(new Date(), "yyyy-MM-dd h:mm:ss AP");
        return retour;
    }


    function viewItem(clItem,showFonctions = false)
    {// Affiche les propriétés d'un élément et , éventuellement les fonctions
        appendLog("===> Elément nom :" + clItem.name + " de type:" + clItem.type);
        for (var p1 in clItem)
        {
            if( typeof clItem[p1] != "function" )
                if(p1 !== "objectName" && (clItem[p1]))
                    appendLog("Propriété " + p1 + ":" + clItem[p1]);
        }
        if (!showFonctions)
            return;
        for (var p2 in clItem)
        {
            if( typeof clItem[p2] == "function" )
                if(p2 !== "objectName" && (clItem[p2]))
                    appendLog("Function " + p2 + ":" + clItem[p2]);
        }
    }



}
