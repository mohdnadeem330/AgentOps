/**
 * __________________________________________________________
 * 
 * Unit Search Controller for Resale Opportunity
 * __________________________________________________________
 * 
 * Developed By Harsh@Aldar June 2023
 * __________________________________________________________
 * 
 * Modification Log
 * __________________________________________________________
 * 
 * ASF-236/936/924
 * __________________________________________________________
 */
import { LightningElement, api, wire, track } from 'lwc';
import getAllProjects from '@salesforce/apex/ResaleComponentController.getAllProjects';
import getAllBuildings from '@salesforce/apex/ResaleComponentController.getAllBuildings';
import getResaleUnitDetails from '@salesforce/apex/ResaleComponentController.getResaleUnitDetails';
import getsObjectType from '@salesforce/apex/ResaleComponentController.getsObjectType';
import lightningdatatableHideColumn from '@salesforce/resourceUrl/lightningdatatableHideColumn'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import { NavigationMixin } from 'lightning/navigation';
import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import { getRecord } from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader'
import fetchSalesOrderRecs from '@salesforce/apex/ResaleComponentController.fetchSalesOrderId';
import updateSobjectJS from '@salesforce/apex/ResaleComponentController.updateSobject';
import fetchResaleDataJS from '@salesforce/apex/ResaleComponentController.fetchResaleData';
import getResaleUnitInfo from '@salesforce/apex/ResaleComponentController.getResaleUnitInfo';
import getVFDomainURL from "@salesforce/apex/ResaleUnitService.getVFDomainURL";
import sendSalesOfferPDF from '@salesforce/apex/ResaleOfferPDFUtility.sendSalesOfferPDF';

const RESALECOLUMNS = [
    { label: 'Unit', fieldName: 'Unit__c' },
    { label: 'Opportunity', fieldName: 'Opportunity__c' },
    { label: 'Offer Price', fieldName: 'Listing_Price__c', type: 'currency',
    typeAttributes: { maximumFractionDigits: '2' } },
    { label: 'Comments', fieldName: 'Comments__c' },
    { label: 'Status', fieldName: 'Status__c' }
];

export default class ResaleUnitSearchController extends NavigationMixin (LightningElement) {
        //used to view a record
        redirecPageUrl;
        //recordId
        @api recordId;
        //current record (Opportunity)
        sObjectRecord;
        //current record's object name (Opportunity)
        sObjectRecordType;
        //page number counter
        pageNumber = 1;
        //selected units
        @track selectedUnits = {};
        @track noSelectionsMade = true;
        //var to toggle spinner
        isLoading=true;
        //Super set of Projects
        projectList;
        selectedProject;
        //sub set for buildings under selected project, reactive
        buildingList;
        selectedBuilding;

        record;
        error;

        @track initialLoad = true;

        // static Filters
        propertyUsageList;
        unitTypesSetList;
        unitModelSetList;
        floorNumberSetList;
        unitBedRoomsSetList;
        unitViewSetList;

        //these contains nested info about selected unit
        @track unitDataTable;
        unitInventoryDetails;
    
        //profile name of currently logged in user
        @track prfName;
        userId = strUserId;
    
        //To get the Resale Unit details
        @track resaleBuildingId;
        @track resaleProjectId;
    
        // ASF 936 START
        @track RESALECOLUMNS = RESALECOLUMNS;
        resaleObjData = {};
        enableProceedforResale = true;
        availableOffers;
        showExistingOfferScreen = false;

        //PDF
        customerName = '';
        fullUrl = '';
        unitId = '';

        // WIRE METHODS START
        //Get Related Account's Owner Id
        @wire(getRecord, { recordId: '$recordId', fields: ['account.OwnerId'] })
        mom;
     
        @wire(getRecord, {
            recordId: strUserId,
            fields: [PROFILE_NAME_FIELD]
        }) wireuser({
            error,
            data
        }) {
            if (error) {
                this.error = error ; 
            } else if (data) {
                this.prfName =data.fields.Profile.value.fields.Name.value;        
            }
        }

        @wire(getRecord, { recordId: '$recordId', layoutTypes: 'Full' })
        wiredRecord({ error, data }) {
            if (data) {
                this.record = data;
                this.error = null;
                this.validateRecordType();
            } else if (error) {
                this.record = null;
                this.error = error;
            }
        }
        // WIRE METHODS END

        validateRecordType() {
            const expectedRecordType = 'Resale';
    
            if (this.record.recordTypeInfo.name !== expectedRecordType) {
                this.error = `The record type is incorrect. Expected: ${expectedRecordType}. Current: ${this.record.recordTypeInfo.name}.`;
            } else {
                this.error = null;
            }
        }

        // CONSTRUCTOR
        constructor() {
            super();
            this.RESALECOLUMNS = this.RESALECOLUMNS.concat( [
                { type: 'action', typeAttributes: { rowActions: this.getRowActions } }
            ] );
        }

        // CALLBACKS START
        connectedCallback(){
            this.gesObjectData();
        }

        renderedCallback(){
            //If CSS was loaded, return
            if(this.isCssLoaded) {
                return;
            }

            this.isCssLoaded = true
            loadStyle(this, lightningdatatableHideColumn).then(()=>{
                // console.log("Loaded Successfully")
            }).catch(error=>{ 
                // console.error("Error in loading the css")
            })

            if(!this.redirecPageUrl && this.recordId ){
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        actionName: 'view',
                    },
                }).then(url => {
                    this.redirecPageUrl = url;
                });
            }
        }
        // CALLBACKS END

        // INIT
        gesObjectData(){
            // console.log('## 144: RecordId: ',this.recordId);
            getsObjectType({recordID :this.recordId })
            .then(data => {
                // console.log('### 144 DATA : ',JSON.stringify(data));
                for(var key in data){
                    this.sObjectRecordType = key;
                    this.sObjectRecord = data[key];
                }
                if(this.sObjectRecordType == 'Opportunity'){
                    this.populateProjects();
                    //this.getOpportunityDetails();
                }
            })
            .catch(error => {
                // console.log('ERRORR: ',JSON.stringify(error));
                this.sObjectRecordType = undefined;
                this.sObjectRecord = undefined;
                this.isLoading=false;
            });
        }

        //GET PROJECTS
        populateProjects(){
            
            getAllProjects()
            .then(data => {
                // console.log('## 168',data);
                // console.log('####this.sObjectRecord.Project__c : ',this.sObjectRecord.Project__c);
                this.projectList = data;
                //ASF-924 Harsh@Aldar 09/06/23
                //if Unit__c is populated, get selected project on basis of Unit__c on Opportunity Record
                if(this.sObjectRecordType == 'Opportunity' && this.sObjectRecord && this.sObjectRecord.SaleType__c == 'Resale'){
                    if(this.sObjectRecord.Unit__c){
                        // console.log('####unitId: this.sObjectRecord.Unit__c: ',this.sObjectRecord.Unit__c);
                        getResaleUnitInfo({unitId: this.sObjectRecord.Unit__c})
                        .then(data=> {
                            // console.log('## 176 ',data);
                            if(data.projectId){
                                this.selectedProject = data.projectId;
                                this.resaleProjectId = data.projectId;
                            }
                            if(this.selectedProject && data.buildingId){
                                this.resaleBuildingId = data.buildingId;
                                this.populateBuildings(true);
                            }else{
                                this.isLoading=false;
                            }
                        })
                        .catch(error => {
                            console.log('#### error ',error.message.body);
                            this.projectList = undefined;
                            this.isLoading=false;
                        });
                    }else{
                        // console.log('#### ELSE data 1 : ',data);
                        // console.log('#### ELSE data 2 : ',data[0]);
                        // console.log('#### ELSE data 3 : ',data[0].value);
                        // console.log('#### ELSE project 4 : ',this.sObjectRecord.Project__c);
                        // If Unit is not populated
                        for(let i = 0; i < data.length; i++){
                            if(this.sObjectRecord && this.sObjectRecord.Project__c && data[i].label == this.sObjectRecord.Project__c){
                                this.selectedProject = data[i].value;
                                break;
                            }
                        }
                        //if still blank, choose 1st item in list
                        if(!this.selectedProject){
                            this.selectedProject = data[0].value;
                        }
                        
                        // console.log('#### ELSE this.selectedProject : ',this.selectedProject);
                        if(this.selectedProject){
                            this.populateBuildings(false);
                        }else{
                            this.isLoading=false;
                        }
                    }
                }else{
                    const evt = new ShowToastEvent({
                        title: 'Opportunity',
                        message: 'Not a resale opportunity. Please check Opportunity fields: Sales Type',
                        variant: 'error',                          
                    });
                    this.dispatchEvent(evt);
                    this.projectList = undefined;
                    this.isLoading=false;
                }
            })
            .catch(error => {
                // console.log('Unable to fetch Project data ==>'+ JSON.stringify(error));
                this.projectList = undefined;
                this.isLoading=false;
            });
        }

        //GET BUILDINGS
        populateBuildings(initialLoad){
            // console.log('## 202');
            getAllBuildings({projectId :this.selectedProject })
            .then(data => {
                this.buildingList = data;
                // console.log('### this.buildingList : ',this.buildingList );
                //ASF-924 Harsh@Aldar 09/06/23
                //ASF if resale opp, set the resale unit on record selected default
                if(this.sObjectRecordType == 'Opportunity' && this.sObjectRecord && this.sObjectRecord.SaleType__c == 'Resale' && this.sObjectRecord.Unit__c && this.resaleBuildingId && initialLoad){
                    this.selectedBuilding = this.resaleBuildingId;
                }else{
                //    console.log('data : ------- >  ',data);
                //    console.log('data[0] : -------->  ',data[0]);
                //    console.log('data[0].value : ---------->   ',data[0].value);
                    this.selectedBuilding = (data && data[0] && data[0].value) ? data[0].value : '';
                    // console.log('#### this.selectedBuilding : - > ',this.selectedBuilding);
                }
                // console.log('#### this.selectedBuilding : ',this.selectedBuilding);
                this.populateUnitData();
                this.isLoading=false;
            })
            .catch(error => {
                // console.log('Unable to fetch Building data ==>'+ JSON.stringify(error));
                this.buildingList = undefined;
                this.isLoading=false;
            });
        }

        //GET UNITS
        populateUnitData(){
            // console.log('## 225');
            //ASF-936 Check if its a resale opp
            //if resale opp, make diff soql call from server
            if(this.sObjectRecordType == 'Opportunity' && 
                this.sObjectRecord && 
                this.sObjectRecord.SaleType__c == 'Resale'){

                        getResaleUnitDetails({buildingsId :this.selectedBuilding})
                        .then(data => {
                            this.processUnitData(data);
                        })
                        .catch(error => {
                            this.isLoading=false;
                            this.handleError(error);
                        });
                    
                    
    
            }
        }

        processUnitData(data){
            if(data){
                // console.log('####data.unitDetailList ',data.unitDetailList);
                this.propertyUsageList = data.propertyUsageList;
                this.unitTypesSetList = data.unitTypesSetList;
                this.unitModelSetList= data.unitModelSetList;
                this.floorNumberSetList= data.floorNumberSetList;
                this.unitBedRoomsSetList= data.unitBedRoomsSetList;
                this.unitViewSetList= data.unitViewSetList;
                this.unitInventoryDetails=data.unitDetailList;
                this.clearStatusFilters();
                this.handleFilterChange();
                if (this.unitInventoryDetails.length > 0) {
                    
                }else{ // THERE ARE NO UNITS
                    // this.availableOffers = undefined;
                    // this.unitDataTable = {};
                    const evt = new ShowToastEvent({
                        title: 'Units',
                        message: 'No unit available for selected filter criteria ',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    // this.isLoading = false;
                }
                this.isLoading=false;
            }
        }

        clearStatusFilters(){
            let allSearchFields = this.template.querySelectorAll('.unitFilter');
            for(let i = 0; i < allSearchFields.length; i++) {
                allSearchFields[i].value='';
            }
        }

        handleError(error) {
            // Handle the error appropriately
        }

        handleFilterChange(){
            // console.log('# IN FILTER CHANGE : ',);
            // clear the unit data table first
            this.unitDataTable = undefined;
            var filteredData = [];

            // console.log('this.unitInventoryDetails'+(this.unitInventoryDetails.length));
            // console.log('this.unitInventoryDetails'+JSON.stringify(this.unitInventoryDetails));
            if(this.unitInventoryDetails){
                let allSearchFields = this.template.querySelectorAll('.unitFilter');
                for(let k = 0; k<this.unitInventoryDetails.length; k++){
                    var filerCondition=true;

                    for(let i = 0; i < allSearchFields.length; i++) {

                        if(allSearchFields[i].value != undefined && allSearchFields[i].value != '' ){
                            if(this.unitInventoryDetails[k].unitDetails[allSearchFields[i].dataset.fieldApi] != allSearchFields[i].value){
                                // console.log('#### ----------------- FILTER CONDITION FALSE        ------------------ ####');
                                filerCondition = false;
                                break;
                            }
                        }
                    }
                    // console.log('# IN FILTER CHANGE : filerCondition ',filerCondition);
                    if(filerCondition){
                        let tempRec = Object.assign({}, this.unitInventoryDetails[k]);

                        tempRec.isSelected = (this.selectedUnits[tempRec.unitDetails.Id]) ? this.selectedUnits[tempRec.unitDetails.Id].selectionStatus : false;
                        
                        
                        //ASF-924 Harsh@Aldar 09/06/23 START
                        if(this.sObjectRecordType == 'Opportunity' && this.sObjectRecord && this.sObjectRecord.SaleType__c == 'Resale' && this.sObjectRecord.Unit__c && this.initialLoad){
                            //if current unit is the resale unit
                            if (this.unitInventoryDetails[k].unitDetails.Id == this.sObjectRecord.Unit__c) {
                                //if it is the same project and building as in filters
                                if(this.selectedProject == this.resaleProjectId && this.selectedBuilding == this.resaleBuildingId){
                                    //if there is more than one selected unit, show toast
                                    if(this.selectedUnits && this.selectedUnits.length > 0){
                                        this.dispatchEvent(
                                            new ShowToastEvent({
                                                title: 'Error',
                                                message: 'Please select only one Unit. Please create separate Lead for New Unit',
                                                variant: 'error',
                                            }),
                                        );
                                    }else{
                                        //On Initial Load, select the Unit present on Resale Opp record, so filling the data of selected record in table
                                        if(this.initialLoad){
                                            console.log(' ---------- INITIAL LOAD ----------------- : ');
                                            tempRec.isSelected = true;
                                            //set the selected item in selectedUnits list
                                            this.selectedUnits[this.sObjectRecord.Unit__c] = {
                                                'selectionStatus': true,
                                                'unitId': this.unitInventoryDetails[k].unitDetails.Id,
                                                'unitName': this.unitInventoryDetails[k].unitDetails.Name,
                                                'unitCode' : this.unitInventoryDetails[k].unitDetails.PropertyId__c,
                                                'ProjectName': this.unitInventoryDetails[k].unitDetails.ProjectName__c,
                                                'sCWaiverFee': this.unitInventoryDetails[k].unitDetails.AnticipatedServiceCharges__c,
                                                'pMFee': this.unitInventoryDetails[k].unitDetails.PropertyManagementFee__c,
                                                'homeMaintenanceFee': this.unitInventoryDetails[k].unitDetails.HomeMaintenanceFee__c,
                                                'unitPrice': this.unitInventoryDetails[k].unitDetails.Listing_Price__c,
                                                'unittype': this.unitInventoryDetails[k].unitDetails.UnitType__c,
                                                'multipurposeamount': this.unitInventoryDetails[k].unitDetails.MultiPurposeAmount__c,
                                                'totalrooms': this.unitInventoryDetails[k].unitDetails.TotalRooms__c,
                                                'saleablearea': this.unitInventoryDetails[k].unitDetails.SaleableArea__c,
                                                'measuredarea': this.unitInventoryDetails[k].unitDetails.MeasuredArea__c,
                                                'terracearea': this.unitInventoryDetails[k].unitDetails.TerraceArea__c,
                                                'onlinereservationfee': this.unitInventoryDetails[k].unitDetails.OnlineReservationFee__c,
                                                'reservationamount': this.unitInventoryDetails[k].unitDetails.ReservationAmount__c,
                                                'mortgageApplicable': false,
                                                'intCommissionAmountField':undefined,
                                                'intCommissionPercentageField':undefined, 
                                                'dataInstallmentLineChanges':[],
                                                'salesOfferDetails':undefined
                                            };
                                        //display list of available offers immediately
                                        //this.refreshOfferTable();

                                        // console.log('#### this.selectedUnits -------- > : ',this.selectedUnits);
                                        }
                                    }
                                }
                            }   
                        }
                        if(Object.keys(this.selectedUnits).length > 0){
                            this.noSelectionsMade = false;
                        }
                        console.log('#### tempRec ------------> : ',tempRec);
                        filteredData.push(tempRec);
                        //ASF-924 Harsh@Aldar 09/06/23 END
                    }
                }
                
            }
            // console.log('##### filteredData ------> : ',filteredData);
            this.unitDataTable = filteredData;
            // console.log('#### -- this.unitDataTable-----------> : ',this.unitDataTable);
            this.initialLoad = false;
            //return filteredData;
        }
    
        getRowActions( row, doneCallback ) {
    
            // const actions = [];
            // console.log('row-->'+row[ 'Status__c' ]);
            // console.log('row-->'+row[ 'Status' ]);
            // if ( row[ 'Status__c' ]  ==  'Approved' ) {
            //     // actions.push( {
            //     //     'label': 'Initiate Trasnfer request',
            //     //     'name': 'Initiate Trasnfer request'
            //     // } );
            //     actions.push( {
            //         'label': 'Cancel',
            //         'name': 'Cancel'
            //     } );
            // } 
            // if ( row[ 'Status__c' ]  ==  'Sent for Approval' ) {
            //     actions.push( {
            //         'label': 'Cancel',
            //         'name': 'Cancel'
            //     } );
            // } 
            // setTimeout( () => {
            //     doneCallback( actions );
            // }, 200 );
    
        }
        // ASF 936 END HARSH
    
        
        /* getters */
        get isPage1(){
            return this.pageNumber == 1 ? true : false;
        }
        
        // Harsh@Aldar -- 08/09/23 -- updated the disable logic	
        get disableResale(){	
            return this.noSelectionsMade;	
        }
        get showPage2(){
            return this.pageNumber == 2;
        }

        get showPage3(){
            return this.pageNumber == 3;
        }
    
        get isResaleOpp(){
            return (this.sObjectRecord && this.sObjectRecord.SaleType__c == 'Resale');
        }
        
        get totalSelectedUnits(){
            var selectedCountToReturn=0;
            if(this.selectedUnits){
                for(var key in this.selectedUnits){
                    if(this.selectedUnits[key].selectionStatus){
                        selectedCountToReturn++;
                    }
                }
            }
            return selectedCountToReturn;
        }
    
        get selectedUnitList(){
            let unitsToReturn = [];
            for(var key in this.selectedUnits){
                if(this.selectedUnits[key].selectionStatus){
                    this.selectedUnits[key].calculatedPayment=undefined;
                    unitsToReturn.push(this.selectedUnits[key]);
                }
            }
            return unitsToReturn;
        }
    
        get isResaleProfile() {
            return (this.prfName == 'Resale Relationship Manager');
        }

        get isSelectorDisabled(){
            return (this.prfName != 'Resale Relationship Manager');
        }


        /* Apex Call Methods */
    
        
        openModal() {
            // to open modal set isModalOpen tarck value as true
            this.showBudgetModal = true;
        }
        closeModal(event) {
            // to close modal set isModalOpen tarck value as false
            //this event has been fired from the modal component it self
            this.showBudgetModal = event.detail.isOpen;
        }

        sendSalesOfferEmail(event){
        this.isLoading=true;
        var currentUnit = event.target.dataset.unitId;
        // console.log('#### SEND PDF EMAIL - currentUnit : ',currentUnit);
        // console.log('#### SEND PDF EMAIL - customerName : ',this.customerName);
        // console.log('#### SEND PDF EMAIL - opportunityId : ',this.recordId);
        sendSalesOfferPDF({ currentUnit : currentUnit , customerName : this.customerName , opportunityId : this.recordId})
        .then(data => {
            this.isLoading=false;
            const evt = new ShowToastEvent({
                title: 'Email Confirmation',
                message: 'Email have been sent successfully.',
                variant: 'success',
            });
            this.dispatchEvent(evt);

            if(currentUnit != undefined && currentUnit !=null && currentUnit !=''){
                this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Opportunity',
                    actionName: 'view'
                    
                }
            });
            }
        })
        .catch(error => {
            // console.log('sending email failed'+ JSON.stringify(error));
            this.isLoading=false;
            const evt = new ShowToastEvent({
                title: 'Email Confirmation',
                message: 'Sending email failed.',
                variant: 'error',
            });
            this.dispatchEvent(evt);
            
        });
    }
        

        async handlePDFActive(event){
            var currentUnit=Object.keys(this.selectedUnits)[0];
            var currentOpp=this.recordId;

            // console.log('#### currentUnit: ',currentUnit);
            // console.log('#### currentOpp: ',currentOpp);

            this.customerName = this.sObjectRecord.Account == undefined ? null : this.sObjectRecord.Account.Name;

            // console.log('####this.this.sObjectRecord.Account.Name : ',this.sObjectRecord.Account.Name);

            if(event.target.dataset.targetType == 'input'){
                this.customerName = event.target.value;
            }

            
            // console.log('#### this.customerName: ',this.customerName);

            var mainUrl = await getVFDomainURL();

            // console.log('####mainUrl : ',mainUrl);

            // mainUrl = 'https://aldarproperties--resaledev--c.sandbox.vf.force.com';

            this.fullUrl = mainUrl + '/apex/ResaleOfferPDF?currentUnit='+currentUnit+'&customerName='+this.customerName+'&opportunityId='+currentOpp;
            // console.log('####this.fullUrl : ',this.fullUrl);
            // this.fullUrl = mainUrl + '/apex/OfferDetailsPDF?id='+this.recordId+'&currentUnit='+currentUnit+'&currentOffer='+currentOffer+'&otherUnits='+otherUnits+'&selectedPayments='+selectedPayments+'&customerName='+this.customerName+'&multiPurposeAmount='+multiPurposeAmountApplicable+'&selectedDesign='+selectedDesign+'&PODselection='+PODselection;

        }

        
        async handleMenuAction(event){
            if (this.totalSelectedUnits > 1) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select only one Unit. In case of new Unit, please create a new Lead',
                        variant: 'error',
                    }),
                );
                return;
            }
            // console.log('handle menu action'+event.target.name );

            if(event.target.name=='BACK'){
                // console.log('#### 544 GO BACK ',Object.keys(this.selectedUnits),'------------> this.pageNumber ',this.pageNumber); 
                if(this.pageNumber == 3){
                    this.pageNumber = this.pageNumber - 2;
                }else{
                    this.pageNumber = this.pageNumber - 1;
                }
                
                this.resaleScreen = false;
                if(this.pageNumber == 1){
                    // this.clearStatusFilters();
                    this.initialLoad = false;
                    this.handleFilterChange();
                }
            }
            if(event.target.name=='OFFER'){
                this.pageNumber = this.pageNumber+2;
                // console.log('#### CHECK INPUT TO PDF - selectedUnits before :  ',this.selectedUnits);
                
                // Accessing the first (and presumably only) value from the selected units
                const selectedUnit = Object.values(this.selectedUnits)[0];

                // Accessing specific properties from the selected unit object
                const unitId = selectedUnit.unitId;
                const unitName = selectedUnit.unitName;
                const projectName = selectedUnit.ProjectName;
                const saleableArea = selectedUnit.saleablearea;

                // Logging the retrieved values
                // console.log('Unit ID:', unitId);
                // console.log('Unit Name:', unitName);
                // console.log('Project Name:', projectName);
                // console.log('Saleable Area:', saleableArea);
            }
            else if(event.target.name =='SENDOFFER'){
                this.populateSelectedValsFlag = false;
                // console.log('#### Object.keys(this.selectedUnits)[0]: ',Object.keys(this.selectedUnits)[0]);
                fetchSalesOrderRecs({unitId:Object.keys(this.selectedUnits)[0]})
                .then(result=>{
                    // console.log('#### 2332323232: ',this.sObjectRecord.SalesOrder__c);
                    // console.log(JSON.stringify(result));
                    if(result != null){   
                        let dataAssigned = {
                            oppId: this.recordId,
                            unitId:Object.keys(this.selectedUnits)[0],
                            // salesOrderId: this.sObjectRecord.SalesOrder__c == undefined ? result.RelatedSalesOrder__c == null ? null : result.RelatedSalesOrder__c : this.sObjectRecord.SalesOrder__c,
                            // salesOrderName: this.sObjectRecord.SalesOrder__c == undefined ? result.RelatedSalesOrder__c == null ? null : result.RelatedSalesOrder__r.Name : this.sObjectRecord.SalesOrder__r.Name,
                            caseId: result?.ListedCase__c,
                            salesOrderId: result?.ListedCase__r?.SalesOrder__c,
                            salesOrderName: result?.ListedCase__r?.SalesOrder__r.Name,
                            unitRecord: result,
                            buyerAccount : this.sObjectRecord.AccountId,
                            buyerName : this.sObjectRecord.Account.Name,
                            buyerEmail : this.sObjectRecord.Account?.PersonEmail,
                            buyerPhone : this.sObjectRecord.Account?.PersonMobilePhone,
                            // sellerAccount : this.sObjectRecord.SalesOrder__c == undefined ? result.RelatedSalesOrder__c != null && result.RelatedSalesOrder__r.Account__c != null ?  result.RelatedSalesOrder__r.Account__c : null : this.sObjectRecord.SalesOrder__r.Account__c,
                            // sellerName : this.sObjectRecord.SalesOrder__c == undefined ? result.RelatedSalesOrder__c != null && result.RelatedSalesOrder__r.Account__c != null ? result.RelatedSalesOrder__r.Account__r.Name : null : this.sObjectRecord.SalesOrder__r.Account__r.Name
                            sellerAccount: result?.ListedCase__r?.AccountId,
                            sellerName: result?.ListedCase__r?.Account?.Name,
                            sellerEmail: result?.ListedCase__r?.Account?.PersonEmail,
                            sellerPhone: result?.ListedCase__r?.Account?.PersonMobilePhone
                        }
                       this.reSaleValues = dataAssigned;
                       this.pageNumber = this.pageNumber+1;
                       this.resaleScreen = true;
                       this.enableProceedforResale = true;
                    }
                    else{
                        //ASF 936 If there is an existing accepted offer, show toast
                        const evt = new ShowToastEvent({
                            title: 'Sales Offer',
                            message: 'This unit has an accepted offer!',
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                    }
                    }).catch(error=>{
                            console.log('error-->'+error);
                    });
            } 
            else if(event.target.name =='PROCEEDRESALE'){
                this.isLoading = true;
                // console.log('####this.resaleObjData PROCEED ',JSON.stringify(this.resaleObjData));
                this.updateResaleData(this.resaleObjData);
            }
            // console.log(JSON.stringify(this.reSaleValues));
        }

        convertToDate(dateTimeString) {
            const options = { year: 'numeric', month: 'long', day: 'numeric', hour: 'numeric', minute: 'numeric', hour12: true };
            const dateTime = new Date(dateTimeString);
            return dateTime.toLocaleString(undefined, options);
        }

        get selectedUnit (){
            return Object.values(this.selectedUnits)[0];
        }
          
    
        // ASF-936 START
        updateResaleData(sObjMap){
            updateSobjectJS({sObjMap:sObjMap})
                .then(result=>{
                    const evt = new ShowToastEvent({
                        title: 'Resale Offer',
                        message: 'Resale Offer Sent!',
                        variant: 'success',
                    });
                    this.isLoading = false;
                    this.pageNumber = 1;
                    this.dispatchEvent(evt);
                    this.navigateToRelatedList();
                    // this.pageNumber = this.pageNumber-1;
                    // this.resaleScreen = false;
                    
                    // this.refreshOfferTable();
                    // this.isLoading = false;
                })
                .catch(error=>{
                    const evt = new ShowToastEvent({
                        title: 'Sales Offer Error',
                        message:  error.body.message ,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    // this.unitDataTable = [];
                    // this.handleFilterChange();
                    // this.pageNumber = this.pageNumber-1;
                    // this.resaleScreen = false;
                    // this.navigateToRelatedList();
                    this.isLoading = false;
                    
                });
        }

        //Take user to Opportunity's Resale Offer Related List
        navigateToRelatedList() {
        // Construct the URL for the related list
        const relatedListUrl = `/lightning/r/Opportunity/${this.recordId}/related/Resale_Offers__r/view`;
        console.log('#### relatedListUrl : ',relatedListUrl);
        // Navigate to the related list
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: relatedListUrl
            }
        });
    }
        
        /**
         * To Refresh the table in the Existing Offers Screen
         * @param {*} param 
         */
        refreshOfferTable(){
            // this.gesObjectData();   
            // console.log('#### REFRESH Object.keys(this.selectedUnits)[0] ',Object.keys(this.selectedUnits)[0]);
            // fetchResaleDataJS({unitId:Object.keys(this.selectedUnits)[0]})
            // .then(result=>{
            //         if(result.length  == 0) {
            //             // const evt = new ShowToastEvent({
            //             //     title: 'Sales Offer',
            //             //     message:  'No Offers in Queue' ,
            //             //     variant: 'error',
            //             // });
            //             // this.dispatchEvent(evt);
            //         }
            //         else{
            //             this.availableOffers = result;
            //             this.availableOffers = this.availableOffers.map(item => ({
            //                 ...item,
            //                 formattedCreatedDate: this.convertToDate(item.CreatedDate)
            //             }));
            //         }
            //     }).catch(error=>{
            //         console.log(error);
            //     });
        }
        // ASF-936 END
    
        /* Handler Methods */
        handleProjectChange(event){
            this.unitDataTable = undefined;
            this.isLoading=true;
            this.selectedProject=event.detail.value;
            // console.log('####selectedProject HANDLE Proj Change : ',this.selectedProject);
            this.populateBuildings(false);
        }
        
        handleBuildingChange(event){
            this.unitDataTable=undefined;
            this.availableOffers = undefined;
            this.isLoading=true;
            this.selectedBuilding=event.detail.value;
            this.populateUnitData();
        }    
        
        
        navigateToRecordPage(event) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: event.target.value,
                    objectApiName: 'Unit__c',
                    actionName: 'view'
                }
            }).then(url => {
                window.open(url, "_blank");
            });
        }   
    
        handleRowSelect(event){
            this.isLoading=true;
            const selectedUnitId = event.target.dataset.id;

            // console.log('#### selectedUnitId: ',selectedUnitId);

            //If Row was selected, uncheck any previously checked item and check the new item
            if(event.target.checked){

                //Uncheck the previously selected row
                if(Object.keys(this.selectedUnits).length > 0){
                    // console.log('#### 712 RS ',Object.keys(this.selectedUnits)); 

                    let oldSelectedRowKey = Object.keys(this.selectedUnits)[0];

                    // console.log('####oldSelectedRowKey RS : ',oldSelectedRowKey);

                    let oldSelectedRow = this.unitDataTable.find(ele => ele.unitDetails.Id == oldSelectedRowKey);
                    // console.log('####oldSelectedRow RS : ',oldSelectedRow);
                    if(oldSelectedRow){
                        oldSelectedRow.isSelected = false;
                    }
                    
                }
                //check the newly selected row
                let newSelectedRow = this.unitDataTable.find(ele => ele.unitDetails.Id == selectedUnitId);
                newSelectedRow.isSelected = true;

                this.selectedUnits = {};
                // this.selectedUnits = [];
                //putting newly selected row data
                this.selectedUnits[selectedUnitId] = {
                    'selectionStatus':event.target.checked,
                    'unitId': event.target.dataset.id, 
                    'unitCode' : event.target.dataset.unitCode,
                    'unitName':event.target.dataset.unitName,
                    'ProjectName':event.target.dataset.unitProject,
                    'sCWaiverFee':event.target.dataset.unitAsc,
                    'pMFee':event.target.dataset.unitPmf,
                    'homeMaintenanceFee':event.target.dataset.unitHmf,
                    'unitPrice':event.target.dataset.unitUnitprice,
                    'unittype':event.target.dataset.unitUnittype,
                    'multipurposeamount':event.target.dataset.unitMultipurposeamount,
                    'totalrooms':event.target.dataset.unitTotalrooms,
                    'saleablearea':event.target.dataset.unitSaleablearea,
                    'measuredarea':event.target.dataset.unitMeasuredarea,
                    'terracearea':event.target.dataset.unitTerracearea,
                    'onlinereservationfee':event.target.dataset.unitOnlinereservationfee,
                    'reservationamount':event.target.dataset.unitReservationamount,
                    'intCommissionAmountField':undefined,
                    'intCommissionPercentageField':undefined, 
                    'dataInstallmentLineChanges':[],
                    'salesOfferDetails':undefined
                };

                // console.log('#### this.selectedUnits 742: ',Object.keys(this.selectedUnits));
                this.noSelectionsMade = false;
                //this.refreshOfferTable();
                
            }else { // If Row was unselected
                // console.log('#### Object.keys(this.selectedUnits) 746: ',Object.keys(this.selectedUnits));
                if(Object.keys(this.selectedUnits).length > 0){
                    
                    let unselectedItemKey = Object.keys(this.selectedUnits)[0];
                    let unselectedItem = this.unitDataTable.find(ele => ele.unitDetails.Id == unselectedItemKey);
                    unselectedItem.isSelected = false;
                    
                }else{
                    this.noSelectionsMade = true;
                }
                // console.log('#### Object.keys(this.selectedUnits) 754: ',Object.keys(this.selectedUnits));
                this.selectedUnits = {};
                this.noSelectionsMade = true;
                // delete this.selectedUnits[selectedUnitId];
            }

            if (Object.keys(this.selectedUnits).length === 0) {
                this.availableOffers = [];
            }
            
            this.isLoading=false;
        }
    

    
        handleChange(event) {
            this[event.target.name] = event.target.value;
        }
    
        doneTypingInterval = 0;
    
        // ASF 936 START
        handleCreateResale(event){
            // console.log('#### handleCreateResale: ',event);
            // console.log('#### handleCreateResale: ',event.detail);
            if(event.detail != null){
                this.resaleObjData = event.detail;
                this.enableProceedforResale = false;
            }
            else{
                this.resaleObjData = {};
                this.enableProceedforResale = true;
            }
        }
        // ASF 936 END
}