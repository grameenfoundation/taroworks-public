// This script traces SObjectContactAssociation and TMU records for a given org
// It will go through 10 TMUs at a time
// To see more, add 10 to the "Offset" number
// Unfortunately it's not possible to query all records at the same time because of APEX limits

Integer offsetToUse = 0;

String csvToWrite = 'TaroWorksMobileUser,ObjectName,ObjectKey,Value\n';


List<gfsurveys__TaroWorks_Mobile_User__c> relevantUserQuery = [
    Select Id, gfsurveys__Assigned_Record_Ids__c, gfsurveys__Username__c from gfsurveys__TaroWorks_Mobile_User__c order by LastModifiedDate desc limit 10 offset :offsetToUse
];

for(gfsurveys__TaroWorks_Mobile_User__c thisTMU: relevantUserQuery) {
    System.debug(JSON.serialize(thisTMU));
    String TMUIds = thisTMU.gfsurveys__Assigned_Record_Ids__c;
    List<String> TMUIdsSplit = TMUIds.split(',');
    String joinedTMUIds = '\''+String.join(TMUIdsSplit,'\',\'')+'\'';
    String associationsQueryString = 'Select Id,gfsurveys__SObjectApiName__c,gfsurveys__AssociatedIds__c,gfsurveys__SObjectFieldApiName__c from gfsurveys__SObjectContactAssociation__c where Id in (' + joinedTMUIds + ')';
    
    System.debug(associationsQueryString);
    List<gfsurveys__SObjectContactAssociation__c> associationsQuery = Database.query(associationsQueryString); 
    
    for(gfsurveys__SObjectContactAssociation__c thisSOCA: associationsQuery){
        System.debug(JSON.serialize(thisSOCA));
        String objectName = thisSOCA.gfsurveys__SObjectApiName__c;
        String objectIds = thisSOCA.gfsurveys__AssociatedIds__c;
        String objectKey = thisSOCA.gfsurveys__SObjectFieldApiName__c;
        List<String> objectIdsSplit = objectIds.split(',');
        String objectIdsJoined = '\''+String.join(objectIdsSplit,'\',\'')+'\''; 
        String dynamicSObjQuery = 'Select ' + objectKey + ' from ' + objectName + ' where Id in (' + objectIdsJoined + ')';
        System.debug(dynamicSObjQuery);
        List<sObject> sobjList = Database.query(dynamicSObjQuery);
        for(sObject referencedObj: sobjList){
            csvToWrite += thisTMU.gfsurveys__Username__c + ',' + objectName + ',' + objectKey + ',' + ((String) referencedObj.get(objectKey)) + '\n';
            System.debug(JSON.serialize(referencedObj));
        }
    }
}

ContentVersion file = new ContentVersion(
title = 'tmuAssociations' + offsetToUse + '.csv',
versionData = Blob.valueOf( csvToWrite ),
pathOnClient = '/tmuAssociations' + offsetToUse + '.csv'
);

insert file;
System.debug( file );

// This script creates a CSV within the client org under "Files" with the output - see instructions here to navigate to the file and download it:
// https://isrovita.wordpress.com/2019/04/23/export-data-as-csv-from-execute-anonymous/