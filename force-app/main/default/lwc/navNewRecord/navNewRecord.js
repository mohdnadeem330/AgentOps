import { api, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getAccount from '@salesforce/apex/NewRecordController.getAccount';
import getRecordTypeId from '@salesforce/apex/NewRecordController.getRecordTypeId';

export default class NavNewRecord extends NavigationMixin(LightningElement) {
    @api recordId;

    connectedCallback() {
        let rcId = this.recordId && this.recordId != null ? this.recordId : new URL(window.location.href).searchParams.get("recordId");
        console.log('rcId>>>' + rcId);
        if (rcId && rcId.substring(0, 3) == '001') {
            this.getAccountRecord(rcId);
        }
    }

    renderedCallback() {
        let rcId = this.recordId && this.recordId != null ? this.recordId : new URL(window.location.href).searchParams.get("recordId");
        console.log('rcId>>>' + rcId);
    }

    getAccountRecord(rcId) {
        getAccount({
            rId: rcId
        }).then(result => {
            let acc = JSON.parse(JSON.stringify(result));
            let dVal = {
                Street: acc.BillingStreet,
                City: acc.BillingCity,
                State: acc.BillingState,
                PostalCode: acc.BillingPostalCode,
                Country: acc.BillingCountry,
                Status: 'In Progress Lead',
                ExistingAccount__c: acc.Id,
                IsCreateFromExistingAccount__c: true,
                Bank_Email__c: acc.BankEmail__c,
                CustomerType__c: acc.CustomerType__c,
                CustomerSubType__c: acc.CustomerSubType__c,
                NameArabic__c: acc.NameInArabic__c,
                RegistrationExpiryDate__c: acc.RegistrationExpiryDate__c,
                RegistrationIssueDate__c: acc.RegistrationIssueDate__c,
                PlaceOfRegistration__c: acc.PlaceOfRegistration__c,
                OwnedBy__c: acc.OwnedBy__c,
                Owner__c: acc.Owner__c,
                TradeName__c: acc.TradeName__c,
                TypeOfCompany__c: acc.TypeOfCompany__c,
                UAEVATRegisterNumber__c: acc.UAEVATRegisterNumber__c,
                UnifiedNumber__c: acc.UnifiedNumber__c,
                CorporateWealthName__c: acc.CorporateWealthName__c
            }
            if (acc.RecordType.Name == 'Person Account') {
                dVal.FirstName = acc.FirstName;
                dVal.MiddleName = acc.MiddleName;
                dVal.LastName = acc.LastName;
                dVal.Salutation = acc.Salutation;
                dVal.Suffix = acc.Suffix;
                dVal.Title = acc.Title;
                dVal.Email = acc.PersonEmail;
                dVal.MobileCountryCode__c = acc.MobileCountryCode__pc;
                dVal.MobileNumber1__c = acc.MobilePhone__pc;
                // dVal.MobileNumber__c = acc.MobilePhone__pc;
            } else {
                dVal.Company = acc.Name;
                dVal.Email = acc.Email__c;
                dVal.MobileCountryCode__c = acc.MobileCountryCode__c;
                dVal.MobileNumber1__c = acc.MobileNumber__c;
                // dVal.MobileNumber__c = acc.MobileNumber__c;
            }
            let rType = acc.RecordType.Name == 'Person Account' ? 'Person' : 'Organization';
            getRecordTypeId({
                objName: 'Lead',
                recordType: rType
            }).then(resultRTId => {
                console.log('dVal>>>', dVal);
                this.openRecord(dVal, 'Lead', '', '', resultRTId);
            }).catch(error => {
                console.error('error', error);
            })
        }).catch(error => {
            console.error('error', error);
        })
    }

    openRecord(dVal, tObjName, navLocation, background, rtId) {
        const defaultValues = encodeDefaultFieldValues(dVal);
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: tObjName,
                actionName: 'new'
            },
            state: {
                count: '1',
                nooverride: '1',
                navigationLocation: navLocation != null ? navLocation : 'LIST_VIEW',
                backgroundContext: background != null ? background : '/lightning/o/' + tObjName + '/list?filterName=Recent',
                defaultFieldValues: defaultValues,
                recordTypeId: rtId && rtId != null ? rtId : null
            }
        });
    }
}