import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import createPriceUpdateReq from '@salesforce/apex/PriceUpdateRequestController.createPriceUpdateReq';
import getuUnitCodes from '@salesforce/apex/PriceUpdateRequestController.getuUnitCodes';
import getActiveProjects from '@salesforce/apex/ProjectService.getAllActiveProjects';
import prepareBuildingsNames from '@salesforce/apex/BuildingSectionService.prepareBuildingsNames';
import prepareOptionList from '@salesforce/apex/UnitService.prepareOptionList';
import getUnitQuery from '@salesforce/apex/UnitService.getUnitQuery';
import { NavigationMixin } from 'lightning/navigation';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import FLOOR_FIELD from '@salesforce/schema/Unit__c.FloorNumber__c';
import UNITTYPE_FIELD from '@salesforce/schema/Unit__c.UnitType__c';
import UNITMODEL_FIELD from '@salesforce/schema/Unit__c.UnitModel__c';
import STATUS_FIELD from '@salesforce/schema/Unit__c.Status__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import UNIT_OBJECT from '@salesforce/schema/Unit__c';
import PriceUpdatePageSize from '@salesforce/label/c.PriceUpdatePageSize';
const columns = [
    { label: 'Unit Code', fieldName: 'Name', type: 'Text' },
    { label: 'Selling Price', fieldName: 'SellingPrice__c', type: 'Decimal' },
    { label: 'New Price', fieldName: 'NewPrice', type: 'Number', editable: true, default:0 },
    { label: 'Status', fieldName: 'Status__c', type: 'text' }
];

export default class PriceUpdateRequest extends NavigationMixin(LightningElement) {

    label = {
        PriceUpdatePageSize
    };
    @track container = {};
    @track selectedIds = [];
    @track message = [];
    @track updateunit = [];
    @track NewPriceVal;
    newPrice = [];
    @track selectedrows = [];
    @track buildingitems = [];
    columns = columns;
    @track selectedrowsdata;
    saveDraftValues = [];
    @track isLoading = false;
    @track comments;
    @track rId;
    @track items = []; //this will hold key, value pair
    @track value = ''; //initialize combo box value
    @track bvalue = '';
    @track fvalue = '';
    @track nbvalue = '';
    @track qry = '';
    @track message;
    @track ProjName = '';
    @track BuildingName = '';
    @track UnitCode = '';
    @track Floor = '';
    @track Status = '';
    @track UnitTypes = '';
    @track UnitModel = '';
    @track Bedroom = '';
    @track showTable;
    @track unitModelValues;
    @track noRecords;
    @track statusvalues;
    @track searchdisableButton = false;
    @track disablebutton = true;
    @track projectTypes;
    @track pupdreq = [];
    @track unitTypeValues;
    @track floorvalues;
    @track isLoading = false;
    fieldWithValues = new Map();

    @track floorOptions = [];
    @track statusOptions = [];
    @track unitTypeOptions = [];
    @track unitModelOptions = [];
    @track badroomvalues = [];
    @track badroomOptions = [];


    filesUploaded = [];
    file;
    fileContents;
    fileReader;
    openfileuploadModal = false;
    closefileuploadModal = false;
    csvFile;
    fileName;
    disableOkButton = true;

    totalPages;
    pageNumber = 1;
    pageSize = PriceUpdatePageSize;
    recordsToDisplay = [];
    totalUnitRecords = 0;
    selectedDatatableRows = [];
    holdingSelectedRowsObj={};
    allSelectedRows = [];
    hasRowError = false;
    errors;
    rowsTableData = [];
    draftValueMap={};
    draftValueMapIds = [];
    errorIds = [];
    dataMap={};
    finalUnitNewPriceAmtMap ={};
    finalUnitNewPriceIds = [];
    finalUnitNewPriceCount = 0;
    disablesendForApproval = true;
    showSaveOptions = false;
    ModalHeader = 'File Upload';
    enableExcel = false;

    @wire(getActiveProjects)
    wiredRecords({ error, data }) {
        if (data) {
            console.log('data>>>', data);
            for (let i = 0; i < data.length; i++) {
                this.items = [...this.items, { value: data[i].Id, label: data[i].Name }];
                console.log('items>>', this.items);
            }
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }

    get projectList() {
        return this.items;
    }

    @wire(prepareBuildingsNames, { projectId: '$ProjName' })
    wiredBuildings({ error, data }) {
        if (data) {
            console.log('buildingdata>>>>', data);

            this.buildingitems = [];
            for (let i = 0; i < data.length; i++) {
                this.buildingitems = [... this.buildingitems, { value: data[i].Id, label: data[i].Name }];
                console.log('items>>', this.buildingitems);
            }
            this.error = undefined;
        } else if (error) {
            this.error = error;

        }
    }
    get BuildingList() {
        return this.buildingitems;
    }

    getOptionList() {
        prepareOptionList({
            projectId: this.ProjName,
            BuildingSectionId: this.BuildingName
        }).then(result => {
            console.log('result>>> ', result);
            let UnitTypeStr = ',';
            let UnitModelStr = ',';
            let FloorNumberStr = ',';
            let StatusStr = ',';
            let BadroomStr = ','

            this.badroomvalues = [];
            this.floorOptions = [];
            this.statusOptions = [];
            this.unitTypeOptions = [];
            this.unitModelOptions = [];
            this.badroomOptions = [];
            for (let op of result) {
                if (op.UnitType__c != null && op.UnitType__c != '' && !UnitTypeStr.includes(',' + op.UnitType__c + ',')) {
                    UnitTypeStr += op.UnitType__c + ',';
                }
                if (op.UnitModel__c != null && op.UnitModel__c != '' && !UnitModelStr.includes(',' + op.UnitModel__c + ',')) {
                    UnitModelStr += op.UnitModel__c + ',';
                }
                if (op.FloorNumber__c != null && op.FloorNumber__c != '' && !FloorNumberStr.includes(',' + op.FloorNumber__c + ',')) {
                    FloorNumberStr += op.FloorNumber__c + ',';
                }
                if (op.Status__c != null && op.Status__c != '' && !StatusStr.includes(',' + op.Status__c + ',')) {
                    StatusStr += op.Status__c + ',';
                }
                if (op.NumberOfBedrooms__c != null && op.NumberOfBedrooms__c != '' && !BadroomStr.includes(',' + op.NumberOfBedrooms__c + ',')) {
                    BadroomStr += op.NumberOfBedrooms__c + ',';
                    this.badroomvalues.push({ 'label': op.NumberOfBedrooms__c, 'value': op.NumberOfBedrooms__c, 'floor': op.FloorNumber__c })
                }
            }
            this.floorOptions = [];
            for (let item of this.floorvalues) {
                if (FloorNumberStr.includes(',' + item.value + ',')) {
                    this.floorOptions.push(item);
                }
            }
            this.statusOptions = [];
            for (let item of this.statusvalues) {
                if (StatusStr.includes(',' + item.value + ',')) {
                   
                    this.statusOptions.push(item);
                }
            }
            this.unitTypeOptions = [];
            for (let item of this.unitTypeValues) {
                if (UnitTypeStr.includes(',' + item.value + ',')) {
                    this.unitTypeOptions.push(item);
                }
            }
            this.unitModelOptions = [];
            for (let item of this.unitModelValues) {
                if (UnitModelStr.includes(',' + item.value + ',')) {
                    this.unitModelOptions.push(item);
                }
            }
        }).catch(error => {
            console.error('error>>> ', error);
        })
    }

    @wire(getObjectInfo, { objectApiName: UNIT_OBJECT })
    unitFloorInfo;

    @wire(getPicklistValues, { recordTypeId: '$unitFloorInfo.data.defaultRecordTypeId', fieldApiName: FLOOR_FIELD })
    floorval({ error, data }) {
        if (data) {
            this.floorvalues = data.values;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$unitFloorInfo.data.defaultRecordTypeId', fieldApiName: STATUS_FIELD })
    statusval({ error, data }) {
        if (data) {
            this.statusvalues = data.values;
            console.log('status values>>>>', this.statusvalues);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$unitFloorInfo.data.defaultRecordTypeId', fieldApiName: UNITTYPE_FIELD })
    unittypeval({ error, data }) {
        if (data) {
            this.unitTypeValues = data.values;
            console.log('unit typepicklist values>>>>', this.unitTypeValues);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$unitFloorInfo.data.defaultRecordTypeId', fieldApiName: UNITMODEL_FIELD })
    unitmodelval({ error, data }) {
        if (data) {
            this.unitModelValues = data.values;
            console.log('unitmpodel  picklist values>>>>', this.unitModelValues);
        }
    }

    handleChange(event) {
        console.log('inside handle change');

        this.qry = 'SELECT Id,Status__c, SellingPrice__c,Name FROM Unit__c';
        if (event.target.name === 'Project') {
            this.ProjName = event.target.value;

            console.log('this.proname === ' + this.ProjName);
            this.getOptionList();
        }
        if (event.target.name === 'Building') {
            this.BuildingName = event.target.value;
            console.log('thisbuilding === ' + this.BuildingName);
            this.getOptionList();
        }
        if (event.target.name === 'UnitCode') {
            this.UnitCode = event.target.value;
            console.log('unitcode === ' + this.UnitCode);
        }
        if (event.target.name === 'Floor Number') {
            this.Floor = event.target.value;
            console.log('Floor === ' + this.Floor);

            this.badroomOptions = [];
            if (this.badroomvalues.length > 0 && this.Floor != null && this.Floor != '') {
                for (let badroom of this.badroomvalues) {
                    if (badroom.floor == this.Floor) {
                        this.badroomOptions.push(badroom);
                    }
                }
            }
        }

        if (event.target.name === 'Bed Rooms') {
            this.Bedroom = event.target.value;
            console.log('bedroom === ' + this.Bedroom);
        }
        if (event.target.name === 'Unit Types') {
            this.UnitTypes = event.target.value;
            console.log('unit types === ' + this.UnitTypes);
        }
        if (event.target.name === 'Status') {
            this.Status = event.target.value;
            console.log('Status === ' + this.Status);
        }
        if (event.target.name === 'Unit Model') {
            this.UnitModel = event.target.value;
            console.log('unit model  === ' + this.UnitModel);
        }

    }


    handleFind() {
        //this.searchdisableButton=true;
        
        this.fileName = '';
        this.csvFile = null;
        this.disableOkButton = true;
        this.selectedDatatableRows =[];
        this.recordsToDisplay = [];
        this.totalPages =null;
        this.showTable = false;
        this.finalUnitNewPriceAmtMap ={};
        this.draftValueMap = {};
        this.dataMap ={};
        this.rowsTableData = [];
        this.draftValueMapIds = [];
        this.errorIds = [];
        this.finalUnitNewPriceIds = [];
        this.finalUnitNewPriceCount = 0;
        console.log('search disable button value' + this.searchdisableButton);
        var whereCon = '';
        this.dataMap={};
        if (this.ProjName.length > 0) {
            if (whereCon.length > 0) {
                whereCon = whereCon + ' AND ';
                console.log('wherecon>>>>>>>', whereCon);
            }
            let prj = "'" + this.ProjName + "'";
            whereCon = whereCon + ' Project__c = ' + prj;
            console.log('Project value>>>>>>>', whereCon);

        }

        if (this.BuildingName.length > 0) {
            if (whereCon.length > 0) {
                whereCon = whereCon + ' AND ';
            }
            let building = "'" + this.BuildingName + "'";
            whereCon = whereCon + ' BuildingSectionName__c = ' + building;
            console.log('building value>>>>>>>', whereCon);
        }

        console.log('unitcode length', this.UnitCode.length);
        if (this.UnitCode.length > 0) {
            if (whereCon.length > 0) {
                whereCon = whereCon + ' AND ';
            }
            let ucode = "'" + this.UnitCode + "'";
            whereCon = whereCon + ' Name = ' + ucode;
            console.log('unit code value>>>>>>>', whereCon);
        }

        if (this.UnitModel.length > 0) {
            if (whereCon.length > 0) {
                whereCon = whereCon + ' AND ';
            }
            let umodel = "'" + this.UnitModel + "'";
            whereCon = whereCon + ' UnitModel__c = ' + umodel;
            console.log('unit model value>>>>>>>', whereCon);
        }

        if (this.Floor.length > 0) {
            if (whereCon.length > 0) {
                whereCon = whereCon + ' AND ';
            }
            let flr = "'" + this.Floor + "'";
            whereCon = whereCon + ' FloorNumber__c = ' + flr;
            console.log('floor value>>>>>>>', whereCon);
        }
        if (this.Bedroom.length > 0) {
            if (whereCon.length > 0) {
                whereCon = whereCon + ' AND ';
            }
            let broom = "'" + this.Bedroom + "'";
            whereCon = whereCon + ' NumberOfBedrooms__c = ' + broom;
            console.log('number of ebdroom value>>>>>>>', whereCon);
        }

        if (this.UnitTypes.length > 0) {
            if (whereCon.length > 0) {
                whereCon = whereCon + ' AND ';
            }
            let utype = "'" + this.UnitTypes + "'";
            whereCon = whereCon + ' UnitType__c = ' + utype;
            console.log('unit type value>>>>>>>', whereCon);
        }

        if (this.Status.length > 0) {
            if (whereCon.length > 0) {
                whereCon = whereCon + ' AND ';
            }
            let statusWhr = "'" + this.Status + "'";
            whereCon = whereCon + ' Status__c = ' + statusWhr;
            console.log('Status value>>>>>>>', whereCon);
        }

        console.log('whereCon ==== > ' + whereCon);
        if (whereCon.length > 0) {
            whereCon = ' Where ' + whereCon;
        }
        this.qry = this.qry + whereCon;
        console.log('qry> ==== ' + this.qry);

        this.isLoading = true;
        getUnitQuery({ query: this.qry }).then(result => {
            this.message = result;
            if (this.message.length === 0) {
                this.showTable = false;
                this.noRecords = true;
                console.log('length ', this.message.length);
                console.log('no Records  ', this.noRecords);
                this.totalUnitRecords = this.message.length;
                this.enableExcel = false;
            } else {
                this.showTable = true;
                this.noRecords = false;
                this.enableExcel = true;
            }

            this.isLoading = false;
            console.log('messgae>>>>', JSON.stringify(this.message));
            for (let i = 0; i < this.message.length; i++) {
                if(this.message[i].NewPrice == undefined ){
                    this.message[i].NewPrice = 0;
                }
                this.dataMap[this.message[i].Id] = this.message[i];
            }
           
            this.paginationHelper();
        }).catch(error => {
            console.log(error);
            this.isLoading = false;
        })
       
    }

    handleShowSubmitApproval(event){
        this.showSaveOptions = true;
        this.openfileuploadModal = true;
        this.ModalHeader = 'Submit for Approval';
    }
    handleSave(event) {
        this.isLoading = true;
        console.log('this.finalUnitNewPriceAmtMap:::'+this.finalUnitNewPriceAmtMap);
        createPriceUpdateReq({ comments: this.comments, newprice: this.finalUnitNewPriceAmtMap})
            .then(result => {
                console.log('inside pur', result);

                this.pupdreq = result;
                console.log(' this.pupdreq>>>', this.pupdreq);
                this.pupdreq.forEach(x => {
                    this.rId = x.Id;
                    console.log('rId ', this.rId);

                    this.isLoading = false;
                    this.resetHandler();
                    this[NavigationMixin.Navigate]
                        ({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: this.rId,
                                objectApiName: 'ProjectUpdateRequest__c',
                                actionName: 'view'
                            }
                        });
                })
            }).catch(error => {
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error,
                        variant: 'error',
                    })
                );
                this.isLoading = false;
            })
            this.openfileuploadModal = false;
    }

    requestCommentsHandler(event) {
        this.comments = event.target.value;
        if(this.finalUnitNewPriceCount > 0 && !this.hasRowError && this.comments != null && this.comments != '' && this.comments != undefined){
            this.disablesendForApproval = false;
        }else{
            this.disablesendForApproval = true;
        }
    }
    getrowsdata() {
        console.log('inside get rowws data');
        var SelectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
        var len = SelectedRecords.length;

        var SelectedRecordIds = '';
        for (let sRecord of SelectedRecords) {
            SelectedRecordIds += sRecord.Id + ',';
        }

        console.log('selected rec>>>', SelectedRecords);
        console.log('length ' + len);
        var priceUpdateUnit = [];
        let isError = false;
        let errorMessage = '';
        if (!isError && (this.comments == undefined || this.comments == null || this.comments == '')) {
            isError = true;
            errorMessage = 'Requestor Comments cannot be blank';
        } else if (!isError && (len == undefined || len == null || len == '' || len <= 0)) {
            isError = true;
            errorMessage = 'Select at least one record to process';
        } else if (!isError && this.saveDraftValues.length < len) {
            isError = true;
            errorMessage = "Selected Unit's price can not be blank/zero";
        } else if (!isError && len > 0) {
            this.saveDraftValues.forEach(item => {
                if (SelectedRecordIds.includes(item.Id) && (item.NewPrice == undefined || item.NewPrice == null || item.NewPrice == '' || item.NewPrice <= 0)) {
                    isError = true;
                    errorMessage = "Selected Unit's price can not be blank/zero";
                } else if (SelectedRecordIds.includes(item.Id)) {
                    priceUpdateUnit.push(item);
                }
            })
        }
        if (!isError) {
            createPriceUpdateReq({ comments: this.comments, newprice: this.finalUnitNewPriceAmtMap})
            .then(result => {
                console.log('inside pur', result);

                this.pupdreq = result;
                console.log(' this.pupdreq>>>', this.pupdreq);
                this.pupdreq.forEach(x => {
                    this.rId = x.Id;
                    console.log('rId ', this.rId);

                    this.isLoading = false;
                    this[NavigationMixin.Navigate]
                        ({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: this.rId,
                                objectApiName: 'ProjectUpdateRequest__c',
                                actionName: 'view'
                            }
                        });
                })
            }).catch(error => {
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error,
                        variant: 'error',
                    })
                );
                this.isLoading = false;
            })
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: errorMessage,
                    variant: 'error',
                })
            );
            this.isLoading = false;
        }
    }

    resetHandler(event) {
        this.message = [];
        this.saveDraftValues = [];
        this.searchdisableButton = false;
        this.UnitCode = '';
        this.Bedroom = '';
        this.BuildingName = '';
        this.ProjName = '';
        this.Floor = '';
        this.UnitTypes = '';
        this.Status = '';
        this.UnitModel = '';
        this.fileName = '';
        this.csvFile = null;
        this.disableOkButton = true;
        this.selectedDatatableRows =[];
        this.recordsToDisplay = [];
        this.totalPages =null;
        this.showTable = false;
        this.finalUnitNewPriceAmtMap ={};
        this.draftValueMap = {};
        this.dataMap ={};
        this.rowsTableData = [];
        this.draftValueMapIds = [];
        this.errorIds = [];
        this.finalUnitNewPriceIds = [];
        this.finalUnitNewPriceCount = 0;
        this.enableExcel = false;
        this.template.querySelectorAll('lightning-input').forEach(element => {
            element.value = null;
        })
        this.template.querySelectorAll('lightning-combobox').forEach(e => {
            e.value = null;
            e.bvalue = null;
            e.ucvalue = null;
            e.statusvalue = null;
            e.utypesvalue = null;
            e.fvalue = null;
            e.nbvalue = null;
            e.saveDraftValues = [];
            e.buildingitems = [];
        })
    }
    handleFilesChange(event){
        this.disableOkButton = true;
        console.clear();
        this.message = [];
        let csvFile = event.detail.files;
        this.fileName = event.detail.files[0].name;
        this.csvFile = csvFile;
        if(event.detail.files[0].name != ''){
         this.disableOkButton = false;
       }
        //Creating a Promise
       
    }
    handlefileUplaod(event){
      this.openfileuploadModal = true;
      this.showSaveOptions = false;
      this.ModalHeader = 'File Upload';
    }
    closeModal(){
        this.openfileuploadModal = false;
    }
    viewDetails(){
        this.isLoading = true;
        let csvFile = this.csvFile;
        let uploadedData = [];
       
        let newPromise = new Promise((resolve, reject) => {
            var reader = new FileReader();
            reader.onload = function () {
                resolve(reader.result);
            };
            reader.readAsText(csvFile[0]);
        })
            .then(result => {
                
                console.log(result);
                var datalist = [];
                var unitCodeList = [];
                uploadedData = result;
                var headers = result.split('\r\n')[0];

                var UnitCode = headers.split(',')[0];
                var SellingPrice = headers.split(',')[1];
                var NewPrice = headers.split(',')[2];
                var Status = headers.split(',')[3];
        if(UnitCode == 'UnitCode' && SellingPrice == 'SellingPrice' && NewPrice == 'NewPrice' && Status =='Status'){
               
            for(var i= 0;i<result.split('\r\n').length; i++){
                    var eachRes;
                    if(result.split('\r\n')[i+1] != null){
                     eachRes = result.split('\r\n')[i+1];
                    }
                    if(eachRes != ''){
                     unitCodeList.push(eachRes.split(',')[0]);
               }
             }
             
          getuUnitCodes({ unitCodes: unitCodeList})
          .then(result => {
            this.isLoading = false;
            for(var i= 0;i<uploadedData.split('\r\n').length; i++){
                var eachRes;
                if(uploadedData.split('\r\n')[i+1] != null){
                 eachRes = uploadedData.split('\r\n')[i+1];
                }
                if(eachRes != ''){
                 unitCodeList.push(eachRes.split(',')[0]);

                 var data = {
                    'Name':eachRes.split(',')[0],
                    'Id': result[eachRes.split(',')[0]],
                    'SellingPrice__c':eachRes.split(',')[1],
                    'NewPrice': (eachRes.split(',')[2] != '' ? eachRes.split(',')[2] : 0),
                    'Status__c':eachRes.split(',')[3]
                }
            datalist.push(data); 
           }
        }
        this.showTable = true;
        this.message = [...datalist];
        for (let i = 0; i < this.message.length; i++) {
           
            if(this.message[i].NewPrice == undefined ){
                this.message[i].NewPrice = 0;
            }
          var draftMap ={'NewPrice': this.message[i].NewPrice, 'Id': this.message[i].Id};
          this.draftValueMap[this.message[i].Id] = draftMap;
          this.dataMap[this.message[i].Id] = this.message[i];
        }
        this.paginationHelper();
        }).catch(error => {
            this.isLoading = false;
            console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error,
                    variant: 'error',
                })
            );
            this.isLoading = false;
        })
            console.log('this.message::'+this.message);
        }else{
            this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Uploaded file is not in proper format',
                    variant: 'error',
                })
            );
            this.resetHandler();
        }
        }).catch(error => {
            this.isLoading = false;
                console.log(error.message.body);
            });
            this.openfileuploadModal = false;
    }
    handlefiletemplateDownload(){
        let columnHeader = ["Unit Code", "Selling Price", "New Price", "Status"];
        let csvIterativeData;  
        let newLineCharacter;  
        let csvSeperator = ",";  
        newLineCharacter = "\n";  
        csvIterativeData = "";  
        csvIterativeData += columnHeader.join(csvSeperator);  
        csvIterativeData += newLineCharacter;  

        this.hrefdata = "data:text/csv;charset=utf-8," + encodeURI(csvIterativeData);  
        csvIterativeData = csvIterativeData.replace(' ', '_SPACE_');
        csvIterativeData = csvIterativeData.replace(/"/g, '');
        csvIterativeData = csvIterativeData.replace('_SPACE_',' ');
        var downloadLink = document.createElement("a"); 
        document.body.appendChild(downloadLink);
        downloadLink.href = 'data:application/vnd.ms-excel,'+csvIterativeData;
        downloadLink.download = 'Unit Price Update Template.xls.csv';
        downloadLink.click();
    }
    get bDisableFirst() {
        return this.pageNumber == 1;
    }
    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }
    paginationHelper(event) {
        console.log('pagination');
        this.recordsToDisplay = [];
        this.totalPages = Math.ceil(this.message.length / this.pageSize);
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
       for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.message.length) {
                break;
            }
            this.recordsToDisplay.push(this.message[i]);
        }  
    }
    previousPage() {
        if(this.selectedDatatableRows.length> 0 && (this.holdingSelectedRowsObj[this.pageNumber ]==null 
            || this.holdingSelectedRowsObj[this.pageNumber].length<=0 )) {      
               this.holdingSelectedRowsObj[this.pageNumber] =this.selectedDatatableRows;
                console.log(this.holdingSelectedRowsObj[this.pageNumber]);
            }  else if(this.holdingSelectedRowsObj[this.pageNumber] != null) {
                this.holdingSelectedRowsObj[this.pageNumber]=this.selectedDatatableRows;
                console.log(this.holdingSelectedRowsObj[this.pageNumber]);
            } 
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
        if(this.holdingSelectedRowsObj[this.pageNumber] != null){
          this.selectedDatatableRows=this.holdingSelectedRowsObj[this.pageNumber];
        }
        for(var i=0; i<=this.totalPages; i++) {
            if(this.holdingSelectedRowsObj[i] != null){
               for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                 if(this.errors == undefined || JSON.stringify(this.errors) == '{}'){
                  this.hasRowError = false;
                 }else if( (this.errors != undefined  || JSON.stringify(this.errors) != '{}' ) && (this.errors.rows[this.holdingSelectedRowsObj[i][j]] == undefined || JSON.stringify(this.errors.rows[this.holdingSelectedRowsObj[i][j]]) == '{}')){
                    this.hasRowError = false;
                   }else{
                    this.hasRowError = true;
                    break;
                 }
                 
            }
            if(this.hasRowError){
                break;
            }
         }
        }
    }
    nextPage() {
        if(this.selectedDatatableRows.length> 0 && (this.holdingSelectedRowsObj[this.pageNumber ]==null 
            || this.holdingSelectedRowsObj[this.pageNumber].length<=0 )){      
               this.holdingSelectedRowsObj[this.pageNumber] =this.selectedDatatableRows;
                console.log(this.holdingSelectedRowsObj[this.pageNumber]);
            } else if(this.holdingSelectedRowsObj[this.pageNumber] != null){
               this.holdingSelectedRowsObj[this.pageNumber]=this.selectedDatatableRows;
             }
            this.pageNumber = this.pageNumber + 1;
            this.paginationHelper();
            if(this.holdingSelectedRowsObj[this.pageNumber] != null){
                this.selectedDatatableRows=this.holdingSelectedRowsObj[this.pageNumber];
            }

            for(var i=0; i<=this.totalPages; i++) {
                if(this.holdingSelectedRowsObj[i] != null){
                   for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                     if(this.errors == undefined || JSON.stringify(this.errors) == '{}'){
                      this.hasRowError = false;
                     }else if( (this.errors != undefined  || JSON.stringify(this.errors) != '{}' ) && (this.errors.rows[this.holdingSelectedRowsObj[i][j]] == undefined || JSON.stringify(this.errors.rows[this.holdingSelectedRowsObj[i][j]]) == '{}')){
                        this.hasRowError = false;
                       }else{
                        this.hasRowError = true;
                        break;
                     }
                     
                }
                if(this.hasRowError){
                    break;
                }   
              }
            }
    }
    firstPage() {
        if(this.selectedDatatableRows.length> 0 && (this.holdingSelectedRowsObj[this.pageNumber ]==null 
            || this.holdingSelectedRowsObj[this.pageNumber].length<=0 )){      
               this.holdingSelectedRowsObj[this.pageNumber] =this.selectedDatatableRows;
                console.log(this.holdingSelectedRowsObj[this.pageNumber]);
            }  else if(this.holdingSelectedRowsObj[this.pageNumber] != null) {
                this.holdingSelectedRowsObj[this.pageNumber]=this.selectedDatatableRows;
                console.log(this.holdingSelectedRowsObj[this.pageNumber]);
            } 
        this.pageNumber = 1;
        this.paginationHelper();
        if(this.holdingSelectedRowsObj[this.pageNumber] != null){
            this.selectedDatatableRows=this.holdingSelectedRowsObj[this.pageNumber];
        }
        for(var i=0; i<=this.totalPages; i++){
            if(this.holdingSelectedRowsObj[i] != null){
               for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                 if(this.errors == undefined || JSON.stringify(this.errors) == '{}'){
                  this.hasRowError = false;
                 }else if( (this.errors != undefined  || JSON.stringify(this.errors) != '{}' ) && (this.errors.rows[this.holdingSelectedRowsObj[i][j]] == undefined || JSON.stringify(this.errors.rows[this.holdingSelectedRowsObj[i][j]]) == '{}')){
                    this.hasRowError = false;
                   }else{
                    this.hasRowError = true;
                    break;
                 }
                 
            }
            if(this.hasRowError){
                break;
            } 
         }
        }
    }
    lastPage() {
        if(this.selectedDatatableRows.length> 0 && (this.holdingSelectedRowsObj[this.pageNumber ]==null 
            || this.holdingSelectedRowsObj[this.pageNumber].length<=0 )){      
               this.holdingSelectedRowsObj[this.pageNumber] =this.selectedDatatableRows;
                console.log(this.holdingSelectedRowsObj[this.pageNumber]);
            }  else if(this.holdingSelectedRowsObj[this.pageNumber] != null) {
                this.holdingSelectedRowsObj[this.pageNumber]=this.selectedDatatableRows;
                console.log(this.holdingSelectedRowsObj[this.pageNumber]);
            } 
        this.pageNumber = this.totalPages;
        this.paginationHelper();
        if(this.holdingSelectedRowsObj[this.pageNumber] != null){
            this.selectedDatatableRows=this.holdingSelectedRowsObj[this.pageNumber];
        }
        for(var i=0; i<=this.totalPages; i++){
            if(this.holdingSelectedRowsObj[i] != null){
               for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                 if(this.errors == undefined || JSON.stringify(this.errors) == '{}'){
                  this.hasRowError = false;
                 }else if( (this.errors != undefined  || JSON.stringify(this.errors) != '{}' ) && (this.errors.rows[this.holdingSelectedRowsObj[i][j]] == undefined || JSON.stringify(this.errors.rows[this.holdingSelectedRowsObj[i][j]]) == '{}')){
                    this.hasRowError = false;
                   }else{
                    this.hasRowError = true;
                    break;
                 }  
            }
            if(this.hasRowError){
                break;
            } 
         }
        }
    }
    handleRowAction(event) {
        console.log('this.dataMap::'+this.dataMap);
        let updatedItemsSet = new Set();
        let selectedItemsSet = new Set(this.holdingSelectedRowsObj[this.pageNumber]);
        let loadedItemsSet = new Set();

        var rowErrorMessages = [];
        var rowErrorFieldName=[];
        var rowError={};

        

        this.message.map((event) => {
            loadedItemsSet.add(event.Id);
        });
        if (event.detail.selectedRows) {
            event.detail.selectedRows.map((event) => {
                updatedItemsSet.add(event.Id);
            }); 
    
            updatedItemsSet.forEach((id) => {
                if (!selectedItemsSet.has(id)) {
                    selectedItemsSet.add(id);
                }
            });        
        }
        loadedItemsSet.forEach((id) => {
            if (selectedItemsSet.has(id) && !updatedItemsSet.has(id)) {
                // Remove any items that were unselected.
                selectedItemsSet.delete(id);
            }
        });

        this.holdingSelectedRowsObj[this.pageNumber] = [...selectedItemsSet];
        console.log('handle row action');
        this.rowsTableData =[];
        let selectedRowsArray = [];
            
        var selectedRows = event.detail.selectedRows;
        this.allSelectedRows = selectedRows;
    
        for (let index = 0; index < selectedRows.length; index++) {
            this.rowsTableData.push(selectedRows[index].Id);
            selectedRowsArray = [...selectedRowsArray, selectedRows[index].Id];
        }
        this.selectedDatatableRows = selectedRowsArray;
        this.finalUnitNewPriceAmtMap = {};
        this.finalUnitNewPriceIds = [];
        this.hasRowError = false;
            for(var i=0; i<=this.totalPages; i++){
                if(this.holdingSelectedRowsObj[i] != null){
                    for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                        if(this.draftValueMap[this.holdingSelectedRowsObj[i][j]] != null){
                            this.finalUnitNewPriceAmtMap[this.holdingSelectedRowsObj[i][j]] = parseFloat(this.draftValueMap[this.holdingSelectedRowsObj[i][j]].NewPrice);
                            this.finalUnitNewPriceIds.push(this.holdingSelectedRowsObj[i][j]);  
                            this.dataMap[this.holdingSelectedRowsObj[i][j]].NewPrice = parseFloat(this.draftValueMap[this.holdingSelectedRowsObj[i][j]].NewPrice);
                        }else{
                            this.dataMap[this.holdingSelectedRowsObj[i][j]].NewPrice = parseFloat(this.dataMap[this.holdingSelectedRowsObj[i][j]].NewPrice); 
                        }
                     if(this.dataMap[this.holdingSelectedRowsObj[i][j]].NewPrice <= 0){
                      rowError[this.dataMap[this.holdingSelectedRowsObj[i][j]].Id]={
                      messages:'Entered value must be valid',
                      fieldNames: 'NewPrice',
                      title: 'We found error'
                    };
                  } else{
                    rowError[this.dataMap[this.holdingSelectedRowsObj[i][j]].Id]={};
                }
               }
            }
        }
         if(rowError != null){
          this.errors = {
             rows:rowError
          }
         }
         this.finalUnitNewPriceCount = this.finalUnitNewPriceIds.length;
         for(var i=0; i<=this.totalPages; i++){
            if(this.holdingSelectedRowsObj[i] != null){
               for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                 if(this.errors == undefined || JSON.stringify(this.errors) == '{}'){
                  this.hasRowError = false;
                 }else if( (this.errors != undefined  || JSON.stringify(this.errors) != '{}' ) && (this.errors.rows[this.holdingSelectedRowsObj[i][j]] == undefined || JSON.stringify(this.errors.rows[this.holdingSelectedRowsObj[i][j]]) == '{}')){
                    this.hasRowError = false;
                   }else{
                    this.hasRowError = true;
                    break;
                 }
            }
            if(this.hasRowError){
                break;
            }
        }
    } 
    if(this.finalUnitNewPriceCount > 0 && !this.hasRowError  && this.comments != null && this.comments != '' && this.comments != undefined){
        this.disablesendForApproval = false;
    }else{
        this.disablesendForApproval = true;
    }
    }
    handlecellchange(event){
     var draftValues = event.detail.draftValues;
     var rowErrorMessages = [];
     var rowErrorFieldName=[];
     var rowError={};
     let draftSelectedIds = this.selectedDatatableRows;


     rowErrorMessages.push('Enter a valid number, Entered value must be numeric and greater than zero')
     rowErrorFieldName.push('NewPrice');
     rowError[draftValues[0].Id]={
        messages:rowErrorMessages,
        fieldNames: rowErrorFieldName,
        title: 'We found error'

      };
      if(draftValues.length>0){
        for(let i=0; i<draftValues.length; i++){
            this.draftValueMap[draftValues[i].Id] = draftValues[i]; 
            this.draftValueMapIds.push(draftValues[i].Id);
         if(!draftSelectedIds.includes(draftValues[i].Id)){
            draftSelectedIds.push(draftValues[0].Id);
            this.dataMap[this.draftValueMap[draftValues[i].Id].Id].NewPrice = draftValues[i].NewPrice;
           }
        }
        this.selectedDatatableRows = [...draftSelectedIds];
        this.holdingSelectedRowsObj[this.pageNumber] = this.selectedDatatableRows;
      }

      if(this.draftValueMapIds != null){
        for(let i=0; i<this.draftValueMapIds.length; i++){
           console.log(this.draftValueMap[this.draftValueMapIds[i]]);
             
            if(this.draftValueMap[this.draftValueMapIds[i]].NewPrice <= 0){
                this.errorIds.push(this.draftValueMapIds[i]);
                rowError[this.draftValueMapIds[i]]={
                    messages:rowErrorMessages,
                    fieldNames: rowErrorFieldName,
                    title: 'We found error'
                };
            }else{
                rowError[this.draftValueMapIds[i]]={};
             }
        }
    }
    if(rowError != null){
        this.errors = {
             rows:rowError
         }
       }
       for(var i=0; i<=this.totalPages; i++){
                if(this.holdingSelectedRowsObj[i] != null){
                    for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
                        if(this.draftValueMap[this.holdingSelectedRowsObj[i][j]] != null){
                            this.finalUnitNewPriceAmtMap[this.holdingSelectedRowsObj[i][j]] = parseFloat(this.draftValueMap[this.holdingSelectedRowsObj[i][j]].NewPrice);
                            this.finalUnitNewPriceIds.push(this.holdingSelectedRowsObj[i][j]); 
                            this.dataMap[this.holdingSelectedRowsObj[i][j]].NewPrice = parseFloat(this.draftValueMap[this.holdingSelectedRowsObj[i][j]].NewPrice); 
                        }else{
                            this.dataMap[this.holdingSelectedRowsObj[i][j]].NewPrice = parseFloat(this.dataMap[this.holdingSelectedRowsObj[i][j]].NewPrice); 
                        }
                    if(this.dataMap[this.holdingSelectedRowsObj[i][j]].NewPrice <= 0){
                    rowError[this.dataMap[this.holdingSelectedRowsObj[i][j]].Id]={
                    messages:'Entered value must be valid',
                    fieldNames: 'NewPrice',
                    title: 'We found error'
                    };
                } else{
                    rowError[this.dataMap[this.holdingSelectedRowsObj[i][j]].Id]={};
                }
              }
             }
            }
      this.finalUnitNewPriceCount = this.finalUnitNewPriceIds.length;
       for(var i=0; i<=this.totalPages; i++){
        if(this.holdingSelectedRowsObj[i] != null){
           for(let j=0; j<this.holdingSelectedRowsObj[i].length;j++ ){
             if(this.errors == undefined || JSON.stringify(this.errors) == '{}'){
              this.hasRowError = false;
             }else if( (this.errors != undefined  || JSON.stringify(this.errors) != '{}' ) && (this.errors.rows[this.holdingSelectedRowsObj[i][j]] == undefined || JSON.stringify(this.errors.rows[this.holdingSelectedRowsObj[i][j]]) == '{}')){
                this.hasRowError = false;
               }else{
                this.hasRowError = true;
                break;
             }
             
        }
         if(this.hasRowError){
            break;
         } 
        }
     }
     if(this.finalUnitNewPriceCount > 0 && !this.hasRowError && this.comments != null && this.comments != '' && this.comments != undefined){
        this.disablesendForApproval = false;
    }else{
        this.disablesendForApproval = true;
    }
   }
   exportAsExcel(){
    console.log('export as Excel');
      let columnHeader = ["UnitCode", "SellingPrice", "NewPrice","Status"]; 

      let jsonKeys = ["Name","SellingPrice__c", "NewPrice", "Status__c"];
      var jsonRecordsData = [];
      for (let i = 0; i < this.message.length; i++) {
           
        if(this.message[i].NewPrice == undefined ){
            this.message[i].NewPrice = 0;
        }
        let msg = this.message[i]
        jsonRecordsData.push(msg);
    }
    console.log('jsonRecordsData::'+jsonRecordsData);
        let csvIterativeData;  
        let csvSeperator ; 
        let newLineCharacter;  
        csvSeperator = ",";  
        newLineCharacter = "\n";  
        csvIterativeData = "";  
        csvIterativeData += columnHeader.join(csvSeperator);  
        csvIterativeData += newLineCharacter;  
        for (let i = 0; i < jsonRecordsData.length; i++) {  
          let counter = 0;  
          for (let iteratorObj in jsonKeys) {  
            let dataKey = jsonKeys[iteratorObj];  
            if (counter > 0) {  csvIterativeData += csvSeperator;  }  
            if (  jsonRecordsData[i][dataKey] !== null &&  jsonRecordsData[i][dataKey] !== undefined ) { 
                console.log(jsonRecordsData[i][dataKey]); 
                csvIterativeData += '"' + jsonRecordsData[i][dataKey] + '"';  
            } else {  csvIterativeData += '""';  
            }  
            counter++;  
          }  
          csvIterativeData += newLineCharacter;  
        }  
        this.hrefdata = "data:text/csv;charset=utf-8," + encodeURI(csvIterativeData);  
        csvIterativeData = csvIterativeData.replace(' ', '_SPACE_');
        if(csvIterativeData.includes('#')){
         csvIterativeData = csvIterativeData.replaceAll('#', '');
        }
        csvIterativeData = csvIterativeData.replace(/"/g, '');
        csvIterativeData = csvIterativeData.replace('_SPACE_',' ');
        var downloadLink = document.createElement("a"); 
        document.body.appendChild(downloadLink);
        downloadLink.href = 'data:application/vnd.ms-excel,'+csvIterativeData;
        downloadLink.download = 'Price Update Request Data.xls.csv';
        downloadLink.click();
     
   }
}