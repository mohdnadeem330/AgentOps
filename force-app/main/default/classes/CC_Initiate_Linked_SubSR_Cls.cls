/*
    Author      : Durga Prasad
    Date        : 15-July-2020
    Description : Custom code to Create Sub / Linked SR
    -----------------------------------------------------------------------------------
*/
global without sharing class CC_Initiate_Linked_SubSR_Cls implements HexaBPM.iSubSRExecutable{
    global void Initiate_SUB_LinkedSR(map < id, id > mapSubSrs, map < id, id > mapLinkedSrs, map < id, id > mapSubSRStepIds, map < id, id > mapLinkedSRStepIds, set < id > setSubSRIds, set < id > setLinkedSRIds){
        //logic for Linked/SUB SR's.
        system.debug('=========test sub sr'+mapSubSrs); 
        system.debug('=========mapLinkedSrssub sr'+mapLinkedSrs);
        system.debug('=========mapSubSRStepIdssr'+mapSubSRStepIds);
        system.debug('=========mapSubSRStepIdssr'+mapSubSRStepIds);
        system.debug('=========mapLinkedSRStepIds'+mapLinkedSRStepIds);
        system.debug('=========mapLinkedSRStepIds'+setSubSRIds);
        system.debug('=========setLinkedSRIds'+setLinkedSRIds);
        map < string, id > mapSRStatus = new map < string, id > ();
        if ((mapSubSrs != null && mapSubSrs.size() > 0) || (mapLinkedSrs != null && mapLinkedSrs.size() > 0))
        {
            list < HexaBPM__SR_Status__c > lstStatus = [select Id, Name from HexaBPM__SR_Status__c where Name = 'Draft'
                or Name = 'Submitted'
            ];
            for (HexaBPM__SR_Status__c objStat: lstStatus)
            {
                mapSRStatus.put(objStat.Name, objStat.id);
            }
            set < id > setAllSRids = new set < id > ();
            if (setSubSRIds != null && setSubSRIds.size() > 0)
            {
                for (Id subSRid: setSubSRIds)
                {
                    setAllSRids.add(subSRid);
                }
            }
            if (setLinkedSRIds != null && setLinkedSRIds.size() > 0)
            {
                for (Id subSRid: setLinkedSRIds)
                {
                    setAllSRids.add(subSRid);
                }
            }
            if (lstStatus != null && lstStatus.size() > 0 && setAllSRids.size() > 0)
            {
                map < string, string > mapSRFullFields = new map < string, string > ();
                map < String, Schema.SObjectType > m = Schema.getGlobalDescribe();
                SObjectType objtype;
                DescribeSObjectResult objDef1;
                map < String, SObjectField > fieldmap;
                if (m.get('Service_Request__c') != null) objtype = m.get('Service_Request__c');
                else objtype = m.get('HexaBPM__Service_Request__c');
                if (objtype != null) objDef1 = objtype.getDescribe();
                if (objDef1 != null) fieldmap = objDef1.fields.getmap();
                if (fieldmap != null)
                {
                    for (string strFld: fieldmap.keyset())
                    {
                        mapSRFullFields.put(strFld.toLowerCase(), strFld.toLowerCase());
                    }
                }
                string SRqry = 'Select Id';
                if (MapSRFullFields != null && MapSRFullFields.size() > 0)
                {
                    for (string srField: MapSRFullFields.keyset())
                    {
                        if (srField.toLowerCase() != 'id') SRqry += ',' + srField;
                    }
                    SRqry += ' From HexaBPM__Service_Request__c where Id IN:setAllSRids';
                }
                map < Id, HexaBPM__Service_Request__c > mapSRS = new map < Id, HexaBPM__Service_Request__c > ();
                for (HexaBPM__Service_Request__c sr: database.query(SRqry))
                {
                    mapSRS.put(sr.Id, sr);
                }
                list < HexaBPM__Service_Request__c > lstSR = new list < HexaBPM__Service_Request__c > ();
                if (mapSubSrs != null && mapSubSrs.size() > 0)
                {
                    for (Id SRTemplId: mapSubSrs.keyset())
                    {
                        Id SRID = mapSubSrs.get(SRTemplId);
                        if (SRID != null && mapSRS.get(SRID) != null)
                        {
                            HexaBPM__Service_Request__c SubSR = new HexaBPM__Service_Request__c();
                            SubSR = mapSRS.get(SRID).clone();
                            SubSR.HexaBPM__Parent_SR__c = mapSRS.get(SRID).Id;
                            SubSR.HexaBPM__SR_Template__c = SRTemplId;
                            SubSR.HexaBPM__Required_Docs_not_Uploaded__c = false;
                            if (mapSubSRStepIds.get(SRTemplId) != null) SubSR.HexaBPM__Parent_Step__c = mapSubSRStepIds.get(SRTemplId);
                            SubSR.HexaBPM__Internal_SR_Status__c = mapSRStatus.get('Draft');
                            SubSR.HexaBPM__External_SR_Status__c = mapSRStatus.get('Draft');

                            if(SRUtility.getSRTemplate(Constants.CHEQUE_REPLACEMENT_SR_TYPE) == SRTemplId){
                                SubSR.SRType__c = Constants.CHEQUE_REPLACEMENT_SR_TYPE;
                            }
                            lstSR.add(SubSR);
                        }
                    }
                }
                if (mapLinkedSrs != null && mapLinkedSrs.size() > 0)
                {
                    for (Id SRTemplId: mapLinkedSrs.keyset())
                    {
                        Id SRID = mapLinkedSrs.get(SRTemplId);
                        if (SRID != null && mapSRS.get(SRID) != null)
                        {
                            HexaBPM__Service_Request__c LinkedSR = new HexaBPM__Service_Request__c();
                            LinkedSR = mapSRS.get(SRID).clone();
                            LinkedSR.HexaBPM__Linked_SR__c = mapSRS.get(SRID).Id;
                            LinkedSR.HexaBPM__SR_Template__c = SRTemplId;
                            LinkedSR.HexaBPM__Required_Docs_not_Uploaded__c = false;
                            if (mapLinkedSRStepIds.get(SRTemplId) != null) 
                                LinkedSR.HexaBPM__Parent_Step__c = mapLinkedSRStepIds.get(SRTemplId);
                            LinkedSR.HexaBPM__Internal_SR_Status__c = mapSRStatus.get('Draft');
                            LinkedSR.HexaBPM__External_SR_Status__c = mapSRStatus.get('Draft');

                            if(SRUtility.getSRTemplate(Constants.CHEQUE_REPLACEMENT_SR_TYPE) == SRTemplId){
                                LinkedSR.SRType__c = Constants.CHEQUE_REPLACEMENT_SR_TYPE;
                            }
                            lstSR.add(LinkedSR);
                        }
                    }
                }
                try
                {
                    if (lstSR != null && lstSR.size() > 0) insert lstSR;
                    system.debug('--lstSR-----'+lstSR[0].id);
                    if (mapSRStatus.get('Submitted') != null)
                    {
                        list < HexaBPM__Service_Request__c > lstSubMitSrs = new list < HexaBPM__Service_Request__c > ();
                        for (HexaBPM__Service_Request__c objSR: lstSR)
                        {
                            HexaBPM__Service_Request__c srSubmitted = new HexaBPM__Service_Request__c(id = objSR.id);
                            srSubmitted.HexaBPM__Internal_SR_Status__c = mapSRStatus.get('Submitted');
                            srSubmitted.HexaBPM__External_SR_Status__c = mapSRStatus.get('Submitted');
                            srSubmitted.HexaBPM__Submitted_Date__c = system.today();
                            srSubmitted.HexaBPM__Submitted_DateTime__c = system.now();
                            lstSubMitSrs.add(srSubmitted);
                        }
                        update lstSubMitSrs;
                        system.debug('--lstSR-----'+lstSubMitSrs[0].id);
                    }
                }catch (Exception e){
                    //GenericUtilityClass.createLog('CC_Initiate_Linked_SubSR_Cls', e.getMessage(), '');
                }
            }
        }
    }
}