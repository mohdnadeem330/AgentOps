import { LightningElement, api, track, wire } from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PRODUCT_OBJECT from "@salesforce/schema/Product2";
import ASSET_OBJECT from "@salesforce/schema/Asset";
import { NavigationMixin } from 'lightning/navigation';
import getClassPackages from '@salesforce/apex/com_AmenityCreationCntrl.getClassPackages';
import updateSchedule from '@salesforce/apex/com_AmenityCreationCntrl.updateClassPackageOnSchedule';
import createDocuments from '@salesforce/apex/com_AmenityCreationCntrl.createDocumentsForClass';
import fetchAccountRecords from '@salesforce/apex/com_AmenityCreationCntrl.getAccountRecords';
import getGroupOptions from '@salesforce/apex/com_AmenityCreationCntrl.getGroupOptions';
import getcommissionTypes from '@salesforce/apex/com_AmenityCreationCntrl.getcommissionTypes';
import getpackageTypes from '@salesforce/apex/com_AmenityCreationCntrl.getpackageTypes';
import createClassPackages from '@salesforce/apex/com_AmenityCreationCntrl.createPackages';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class Com_CreateClassPackages extends LightningElement {
    @track objectInfo;
    @wire(getObjectInfo, { objectApiName: PRODUCT_OBJECT })
    objectInfo;

    @wire(getObjectInfo, { objectApiName: ASSET_OBJECT })
    assetObjectInfo;

    showSpinner = false;
    showClassPackageScreen = true;
    showClassSchedule = false;
    remainingCount = 32768;
    showVatAmountFields = false;


    @api recordId;
    
    classId;
    classPackageList = [];
    classScheduleList = [];

    packageOptions = [];
    classPackage = '';
    @track classPackagesList = [];
    @track scheduleNamesList = [];

    keyIndex = 0;
    @track itemList = [
        {
            id: 0,
            sobjectType: 'Product2',
            Name : '',
            Com_Class__c : this.recordId,
            Com_Group__c : '',
            Com_Commission_Type__c : '',
            Com_Package_Type__c : '',
            Com_Total_No_of_Sessions__c : '',
            Description : '',
            Com_Service_Provider_Commission__c :'',
            Com_Related_Party_Commission__c : '',
            Com_Aldar_ECSS_Commission__c : '',
            Com_Service_Provider_Commission_Amount__c : '',
            Com_Related_Party_Commission_Amount__c : '',
            Com_Aldar_ECSS_Commission_Amount__c : '',
            Com_Fees_AED__c : '',
            Com_Age_Range__c : '',
            Com_Maximum_No_of_Applicants__c : '',
            showPercent : false,
            showAmount : false,
        }
    ];

    groupOptions = [];
    @wire(getGroupOptions)
    getGroupOptions({ error, data }) {
        if (data) {
            this.groupOptions = data;
        } else if (error) {
            this.showToast('Error', 'Error loading industry options', 'error');
        }
    }

    commissionTypes = [];
    @wire(getcommissionTypes)
    getcommissionTypes({ error, data }) {
        if (data) {
            this.commissionTypes = data;
        } else if (error) {
            this.showToast('Error', 'Error loading industry options', 'error');
        }
    }

    packageTypes = [];
    @wire(getpackageTypes)
    getpackageTypes({ error, data }) {
        if (data) {
            this.packageTypes = data;
        } else if (error) {
            this.showToast('Error', 'Error loading industry options', 'error');
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('currentPageReference ', currentPageReference);
            //it gets executed before the connected callback and avilable to use
            this.recordId = currentPageReference.state.recordId;
        }
    }

    get recordClassTypeId() {
        if(this.objectInfo.data) {
            const rtis = this.objectInfo.data.recordTypeInfos;
            return Object.keys(rtis).find((rti) => rtis[rti].name === "Class");
        }else{
            return {}; // An empty mapping for now...
        }
    }

    get recordClassPackageTypeId() {
        if(this.objectInfo.data) {
            const rtis = this.objectInfo.data.recordTypeInfos;
            return Object.keys(rtis).find((rti) => rtis[rti].name === "Class Package");
        }else{
            return {}; // An empty mapping for now...
        }
    }

    get recordClassScheduleTypeId() {
        if(this.assetObjectInfo.data) {
            const rtis = this.assetObjectInfo.data.recordTypeInfos;
            return Object.keys(rtis).find((rti) => rtis[rti].name === "Class Schedule");
        }else{
            return {}; // An empty mapping for now...
        }
    }

    connectedCallback() {
        console.log('from connectedcallback'+this.recordId);
        this.showClassPackageScreen = true;
    }

    handleClassPackageSubmit(event) {
        var requiredFieldsMissing = false;
        var commissionTotalMismatch = false;
        
        this.itemList.forEach(function(productObj){
            
            if(productObj.Name == '' || productObj.Com_Total_No_of_Sessions__c == '' || productObj.Description == '' || productObj.Com_Fees_AED__c == '' || productObj.Com_Age_Range__c == '' 
                || productObj.Com_Maximum_No_of_Applicants__c == '' || productObj.Com_Commission_Type__c == '' ||
                (productObj.Com_Commission_Type__c == 'Percentage' && (productObj.Com_Service_Provider_Commission__c == '' || productObj.Com_Related_Party_Commission__c == '' || productObj.Com_Aldar_ECSS_Commission__c == '')) ||
                    (productObj.Com_Commission_Type__c == 'Amount' && (productObj.Com_Service_Provider_Commission_Amount__c == '' || productObj.Com_Related_Party_Commission_Amount__c == '' || productObj.Com_Aldar_ECSS_Commission_Amount__c == ''))){
                    requiredFieldsMissing = true;
            }else{
                if(productObj.Com_Commission_Type__c == 'Percentage'){
                    var totalPercentage = parseFloat(productObj.Com_Aldar_ECSS_Commission__c) + parseFloat(productObj.Com_Related_Party_Commission__c) + parseFloat(productObj.Com_Service_Provider_Commission__c);
                    if(totalPercentage != 100){
                        commissionTotalMismatch = true;
                    }
                }else{
                    var totalAmount = parseFloat(productObj.Com_Service_Provider_Commission_Amount__c) + parseFloat(productObj.Com_Related_Party_Commission_Amount__c) + parseFloat(productObj.Com_Aldar_ECSS_Commission_Amount__c);
                    if(totalAmount != parseFloat(productObj.Com_Fees_AED__c)){
                        commissionTotalMismatch = true;
                    }
                }
            }
            
        });

        if(requiredFieldsMissing){
            const requiredFieldMissingEvent = new ShowToastEvent({
                title: 'Error!',
                message: 'Required Field(s) missing on one or more Package!',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(requiredFieldMissingEvent);
        }else if(commissionTotalMismatch){
            const commissionTotalMismatchEvent = new ShowToastEvent({
                title: 'Error!',
                message: 'Commissions mismatched for one or more Package! Please make sure Commission(%) is equal to 100% or Commission total is equal to Fees.',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(commissionTotalMismatchEvent);
        }else{
            this.showSpinner = true;
            createClassPackages({classId : this.recordId, packageList : this.itemList})
            .then(result => {
                var newOptions = [];
                setTimeout(() => {
                    result.forEach(function(packageRecord){
                        newOptions.push({label:packageRecord.Name , value : packageRecord.Id });
                    });

                    this.packageOptions = newOptions;
                    this.showSpinner = false;

                    const classPacakageEvent = new ShowToastEvent({
                        title: 'Success!',
                        message: 'Class package has been succesfully added!.',
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(classPacakageEvent);

                    this.keyIndex = 0;
                    this.itemList = [
                        {
                            id: 0
                        }
                    ];
                    
                    this.showClassPackageScreen = false;
                    this.showSpinner = false;
                    this.showClassSchedule = true;
                }, 1000);
            })
            .catch(error => {
                console.log('Errorured:- '+ JSON.stringify(error));
            });
        }
    }

    handleClassScheduleSubmit(event) {
        this.showSpinner = true;
        event.preventDefault();       // stop the form from submitting
        var isVal = true;
        this.template.querySelectorAll('lightning-input-field').forEach(element => {
            isVal = isVal && element.reportValidity();
        });
        
        this.template.querySelectorAll('lightning-record-edit-form').forEach(element => {
            element.submit();
        });
    }

    handleClassScheduleSuccess(event) {
        console.log('handleClassScheduleSuccess');
        console.log(event.detail.id);

        updateSchedule({classId : this.recordId, packgeList : this.classPackagesList, scheduleNamesList: this.scheduleNamesList, scheduleId : event.detail.id})
        .then(result => {
            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error => {
            console.log('Errorured:- '+ JSON.stringify(error));
        });
    }

    handleTAndCChange(event){
        this.remainingCount = 32768 - parseInt(event.target.value.length);
    }

    
    handleVatIncludedChange(event){
        if(event.target.value == 'Yes'){
            this.showVatAmountFields = true;
        }else{
            this.showVatAmountFields = false;
        }
    }

    handleCommissionTypeChange(event){
        if(event.target.value == 'Percentage'){
            this.showCommissionPercentFields = true;
            this.showCommissionAmountFields = false;
        }else if(event.target.value == 'Amount'){
            this.showCommissionAmountFields = true;
            this.showCommissionPercentFields = false;
        }else{
            this.showCommissionPercentFields = false;
            this.showCommissionAmountFields = false;
        }
    }

    addPackageRow() {
        ++this.keyIndex;
        var newItem = [{
            id: this.keyIndex,
            sobjectType: 'Product2',
            Com_Class__c : this.recordId,
            Com_Group__c : '',
            Com_Commission_Type__c : '',
            Com_Package_Type__c : '',
            Com_Total_No_of_Sessions__c : '',
            Description : '',
            Com_Service_Provider_Commission__c :'',
            Com_Related_Party_Commission__c : '',
            Com_Aldar_ECSS_Commission__c : '',
            Com_Service_Provider_Commission_Amount__c : '',
            Com_Related_Party_Commission_Amount__c : '',
            Com_Aldar_ECSS_Commission_Amount__c : '',
            Com_Fees_AED__c : '',
            Com_Age_Range__c : '',
            Com_Maximum_No_of_Applicants__c : '',
            showPercent : false,
            showAmount : false,
        }];

        this.itemList = this.itemList.concat(newItem);
    }

    addRow() {
        ++this.keyIndex;
        var newItem = [{ id: this.keyIndex }];
        this.itemList = this.itemList.concat(newItem);
        
    }

    removeRow(event) {
        if (this.itemList.length >= 2) {
            this.itemList = this.itemList.filter(function (element) {
                return parseInt(element.id) !== parseInt(event.target.accessKey);
            });
        }

        if(showClassSchedule){
            this.classPackagesList.splice(event.target.accessKey, 1);
            this.scheduleNamesList.splice(event.target.accessKey, 1);
        }
    }

    handlePackageChange(event){
        this.classPackagesList[event.target.accessKey] = event.detail.value;
    }

    handleScheduleNameChange(event){
        this.scheduleNamesList[event.target.accessKey] = event.detail.value;
    }

    updateProduct(event){
        console.log(event.target.dataset.field);
        console.log(event.detail.value);
        console.log(event.target.accessKey);

        switch (event.target.dataset.field) {
        case 'Name':
            this.itemList[event.target.accessKey].Name = event.detail.value;
            break;
        case 'Com_Group__c':
            this.itemList[event.target.accessKey].Com_Group__c = event.detail.value;
            break;
        case 'Com_Total_No_of_Sessions__c':
            this.itemList[event.target.accessKey].Com_Total_No_of_Sessions__c = event.detail.value;
            break;
        case 'Description':
            this.itemList[event.target.accessKey].Description = event.detail.value;
            break;
        case 'Com_Commission_Type__c':
            this.itemList[event.target.accessKey].Com_Commission_Type__c = event.detail.value;
            if(event.detail.value == 'Amount'){
                this.itemList[event.target.accessKey].showPercent = false;
                this.itemList[event.target.accessKey].showAmount = true;

                this.itemList[event.target.accessKey].Com_Service_Provider_Commission__c = '';
                this.itemList[event.target.accessKey].Com_Related_Party_Commission__c = '';
                this.itemList[event.target.accessKey].Com_Aldar_ECSS_Commission__c = '';
                
            }else{
                this.itemList[event.target.accessKey].showAmount = false;
                this.itemList[event.target.accessKey].showPercent = true;

                this.itemList[event.target.accessKey].Com_Service_Provider_Commission_Amount__c = '';
                this.itemList[event.target.accessKey].Com_Related_Party_Commission_Amount__c = '';
                this.itemList[event.target.accessKey].Com_Aldar_ECSS_Commission_Amount__c = '';
            }
            break;
        case 'Com_Service_Provider_Commission__c':
            this.itemList[event.target.accessKey].Com_Service_Provider_Commission__c = event.detail.value;
            break;
        case 'Com_Related_Party_Commission__c':
            this.itemList[event.target.accessKey].Com_Related_Party_Commission__c = event.detail.value;
            break;
        case 'Com_Aldar_ECSS_Commission__c':
            this.itemList[event.target.accessKey].Com_Aldar_ECSS_Commission__c = event.detail.value;
            break;
        case 'Com_Service_Provider_Commission_Amount__c':
            this.itemList[event.target.accessKey].Com_Service_Provider_Commission_Amount__c = event.detail.value;
            break;
        case 'Com_Related_Party_Commission_Amount__c':
            this.itemList[event.target.accessKey].Com_Related_Party_Commission_Amount__c = event.detail.value;
            break;
        case 'Com_Aldar_ECSS_Commission_Amount__c':
            this.itemList[event.target.accessKey].Com_Aldar_ECSS_Commission_Amount__c = event.detail.value;
            break;
        case 'Com_Package_Type__c':
            this.itemList[event.target.accessKey].Com_Package_Type__c = event.detail.value;
            break;
        case 'Com_Fees_AED__c':
            this.itemList[event.target.accessKey].Com_Fees_AED__c = event.detail.value;
            break;
        case 'Com_Age_Range__c':
            this.itemList[event.target.accessKey].Com_Age_Range__c = event.detail.value;
            break;
        case 'Com_Maximum_No_of_Applicants__c':
            this.itemList[event.target.accessKey].Com_Maximum_No_of_Applicants__c = event.detail.value;
            break;
        default:
            this.itemList[event.target.accessKey].Name = event.detail.value;
        }

    }
}