global without sharing class CC_Update_sObject implements HexaBPM.iFieldUpdateExecutable {
    global string UpdatesObject(HexaBPM__Action__c act, HexaBPM__Step__c stp) {
        string strResult = 'Success';
        if (stp != null && stp.Id != null) {
            if (act.HexaBPM__Action_Type__c == 'HexaBPM__Service_Request__c') {
                if (stp.HexaBPM__SR__c != null) {
                    HexaBPM__Service_Request__c updateSR = new HexaBPM__Service_Request__c(id = stp.HexaBPM__SR__c);
                    if (act.HexaBPM__Field_Name__c != null && act.HexaBPM__Field_Type__c != null && act.HexaBPM__Value_or_Field__c == 'Value'){
                        if (act.HexaBPM__Field_Type__c == 'DOUBLE') {
                            updateSR.put(act.HexaBPM__Field_Name__c, integer.valueOf(act.HexaBPM__Field_Value__c));
                        } else if (act.HexaBPM__Field_Type__c == 'DATE') {
                            if (act.HexaBPM__Field_Value__c != null && act.HexaBPM__Field_Value__c != '' && act.HexaBPM__Field_Value__c.trim().length() == 10) {
                                list < string > lstDtVals = new list < String > ();
                                lstDtVals = act.HexaBPM__Field_Value__c.split('/');
                                if (lstDtVals != null && lstDtVals.size() == 3) {
                                    Date dateval = Date.newInstance(integer.valueOf(lstDtVals[2]), integer.valueOf(lstDtVals[1]), integer.valueOf(lstDtVals[0]));
                                    updateSR.put(act.HexaBPM__Field_Name__c, dateval);
                                }
                            }
                        } else if (act.HexaBPM__Field_Type__c == 'BOOLEAN') {
                            boolean bval = false;
                            if (act.HexaBPM__Field_Value__c == 'true') {
                                bval = true;
                            }
                            updateSR.put(act.HexaBPM__Field_Name__c, bval);
                        } else {
                            updateSR.put(act.HexaBPM__Field_Name__c, string.valueOf(act.HexaBPM__Field_Value__c));
                        }
                    } else if (act.HexaBPM__Field_Name__c != null && act.HexaBPM__Field_Type__c != null && act.HexaBPM__Value_or_Field__c == 'Step Field' && act.HexaBPM__Field_Value__c != null && act.HexaBPM__Field_Value__c != '') {
                        updateSR.put(act.HexaBPM__Field_Name__c, stp.get(act.HexaBPM__Field_Value__c));
                    }
                    try {
                        update updateSR;
                    } catch (Exception e) {
                        strResult = e.getMessage() + '';
                    }
                }
            } else if (act.HexaBPM__Action_Type__c == 'HexaBPM__Step__c') {
                HexaBPM__Step__c updatestp = new HexaBPM__Step__c(id = stp.Id);
                if (act.HexaBPM__Field_Name__c != null && act.HexaBPM__Field_Type__c != null && act.HexaBPM__Value_or_Field__c == 'Value') {
                    if (act.HexaBPM__Field_Type__c == 'DOUBLE') {
                        updatestp.put(act.HexaBPM__Field_Name__c, integer.valueOf(act.HexaBPM__Field_Value__c));
                    } else if (act.HexaBPM__Field_Type__c == 'DATE') {
                        if (act.HexaBPM__Field_Value__c != null && act.HexaBPM__Field_Value__c != '' && act.HexaBPM__Field_Value__c.trim().length() == 10) {
                            list < string > lstDtVals = new list < String > ();
                            lstDtVals = act.HexaBPM__Field_Value__c.split('/');
                            if (lstDtVals != null && lstDtVals.size() == 3) {
                                Date dateval = Date.newInstance(integer.valueOf(lstDtVals[2]), integer.valueOf(lstDtVals[1]), integer.valueOf(lstDtVals[0]));
                                updatestp.put(act.HexaBPM__Field_Name__c, dateval);
                            }
                        }
                    } else if (act.HexaBPM__Field_Type__c == 'BOOLEAN') {
                        boolean bval = false;
                        if (act.HexaBPM__Field_Value__c == 'true') {
                            bval = true;
                        }
                        updatestp.put(act.HexaBPM__Field_Name__c, bval);
                    } else {
                        updatestp.put(act.HexaBPM__Field_Name__c, string.valueOf(act.HexaBPM__Field_Value__c));
                    }
                } else if (act.HexaBPM__Field_Name__c != null && act.HexaBPM__Field_Type__c != null && act.HexaBPM__Value_or_Field__c == 'SR Field' && act.HexaBPM__Field_Value__c != null && act.HexaBPM__Field_Value__c != '') {
                    updatestp.put(act.HexaBPM__Field_Name__c, stp.HexaBPM__SR__r.get(act.HexaBPM__Field_Value__c));
                }
                try {
                    update updatestp;
                } catch (Exception e) {
                    strResult = e.getMessage() + '';
                }
            } else if (act.HexaBPM__Action_Type__c == 'Account') {
                HexaBPM__Service_Request__c serviceRequest = [SELECT Id, HexaBPM__Customer__c FROM HexaBPM__Service_Request__c WHERE Id =: stp.HexaBPM__SR__c];
                if (stp.HexaBPM__SR__c != null && serviceRequest.HexaBPM__Customer__c != null) {
                    Account updateAcc = new Account(id = serviceRequest.HexaBPM__Customer__c);
                    if (act.HexaBPM__Field_Name__c != null && act.HexaBPM__Field_Type__c != null && act.HexaBPM__Value_or_Field__c == 'Value') {
                        if (act.HexaBPM__Field_Type__c == 'DOUBLE') {
                            updateAcc.put(act.HexaBPM__Field_Name__c, integer.valueOf(act.HexaBPM__Field_Value__c));
                        } else if (act.HexaBPM__Field_Type__c == 'DATE') {
                            if (act.HexaBPM__Field_Value__c != null && act.HexaBPM__Field_Value__c != '' && act.HexaBPM__Field_Value__c.trim().length() == 10) {
                                list < string > lstDtVals = new list < String > ();
                                lstDtVals = act.HexaBPM__Field_Value__c.split('/');
                                if (lstDtVals != null && lstDtVals.size() == 3) {
                                    Date dateval = Date.newInstance(integer.valueOf(lstDtVals[2]), integer.valueOf(lstDtVals[1]), integer.valueOf(lstDtVals[0]));
                                    updateAcc.put(act.HexaBPM__Field_Name__c, dateval);
                                }
                            }
                        } else if (act.HexaBPM__Field_Type__c == 'BOOLEAN') {
                            boolean bval = false;
                            if (act.HexaBPM__Field_Value__c == 'true') {
                                bval = true;
                            }
                            updateAcc.put(act.HexaBPM__Field_Name__c, bval);
                        } else {
                            updateAcc.put(act.HexaBPM__Field_Name__c, string.valueOf(act.HexaBPM__Field_Value__c));
                        }
                    } else if (act.HexaBPM__Field_Name__c != null && act.HexaBPM__Field_Type__c != null && act.HexaBPM__Value_or_Field__c == 'SR Field' && act.HexaBPM__Field_Value__c != null && act.HexaBPM__Field_Value__c != '') {
                        updateAcc.put(act.HexaBPM__Field_Name__c, stp.HexaBPM__SR__r.get(act.HexaBPM__Field_Value__c));
                    } else if (act.HexaBPM__Field_Name__c != null && act.HexaBPM__Field_Type__c != null && act.HexaBPM__Value_or_Field__c == 'Step Field' && act.HexaBPM__Field_Value__c != null && act.HexaBPM__Field_Value__c != '') {
                        updateAcc.put(act.HexaBPM__Field_Name__c, stp.get(act.HexaBPM__Field_Value__c));
                    }
                    try {
                        update updateAcc;
                    } catch (Exception e) {
                        strResult = e.getMessage() + '';
                    }
                }
            } else if (act.HexaBPM__Action_Type__c == 'Contact') {
                HexaBPM__Service_Request__c serviceRequest = [SELECT Id, HexaBPM__Contact__c FROM HexaBPM__Service_Request__c WHERE Id =: stp.HexaBPM__SR__c];
                if (stp.HexaBPM__SR__c != null && serviceRequest.HexaBPM__Contact__c != null) {
                    Contact updateContact = new Contact(id = serviceRequest.HexaBPM__Contact__c);
                    if (act.HexaBPM__Field_Name__c != null && act.HexaBPM__Field_Type__c != null && act.HexaBPM__Value_or_Field__c == 'Value') {
                        if (act.HexaBPM__Field_Type__c == 'DOUBLE') {
                            updateContact.put(act.HexaBPM__Field_Name__c, integer.valueOf(act.HexaBPM__Field_Value__c));
                        } else if (act.HexaBPM__Field_Type__c == 'DATE') {
                            if (act.HexaBPM__Field_Value__c != null && act.HexaBPM__Field_Value__c != '' && act.HexaBPM__Field_Value__c.trim().length() == 10) {
                                list < string > lstDtVals = new list < String > ();
                                lstDtVals = act.HexaBPM__Field_Value__c.split('/');
                                if (lstDtVals != null && lstDtVals.size() == 3) {
                                    Date dateval = Date.newInstance(integer.valueOf(lstDtVals[2]), integer.valueOf(lstDtVals[1]), integer.valueOf(lstDtVals[0]));
                                    updateContact.put(act.HexaBPM__Field_Name__c, dateval);
                                }
                            }
                        } else if (act.HexaBPM__Field_Type__c == 'BOOLEAN') {
                            boolean bval = false;
                            if (act.HexaBPM__Field_Value__c == 'true') {
                                bval = true;
                            }
                            updateContact.put(act.HexaBPM__Field_Name__c, bval);
                        } else {
                            updateContact.put(act.HexaBPM__Field_Name__c, string.valueOf(act.HexaBPM__Field_Value__c));
                        }
                    } else if (act.HexaBPM__Field_Name__c != null && act.HexaBPM__Field_Type__c != null && act.HexaBPM__Value_or_Field__c == 'SR Field' && act.HexaBPM__Field_Value__c != null && act.HexaBPM__Field_Value__c != '') {
                        updateContact.put(act.HexaBPM__Field_Name__c, stp.HexaBPM__SR__r.get(act.HexaBPM__Field_Value__c));
                    } else if (act.HexaBPM__Field_Name__c != null && act.HexaBPM__Field_Type__c != null && act.HexaBPM__Value_or_Field__c == 'Step Field' && act.HexaBPM__Field_Value__c != null && act.HexaBPM__Field_Value__c != '') {
                        updateContact.put(act.HexaBPM__Field_Name__c, stp.get(act.HexaBPM__Field_Value__c));
                    }
                    try {
                        update updateContact;
                    } catch (Exception e) {
                        strResult = e.getMessage() + '';
                    }
                }
            }
        }
        return strResult;
    }
}