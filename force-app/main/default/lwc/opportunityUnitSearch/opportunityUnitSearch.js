import { LightningElement,api,wire, track } from 'lwc'; 
import { createRecord } from 'lightning/uiRecordApi';
import getAllProjects from '@salesforce/apex/OpportunityUnitSearchController.getAllProjects';
import getAllBuildings from '@salesforce/apex/OpportunityUnitSearchController.getAllBuildings';
import getUnitDetails from '@salesforce/apex/OpportunityUnitSearchController.getUnitDetails';
import generateSalesOffer from '@salesforce/apex/OpportunityUnitSearchController.generateSalesOffer';
import sendSalesOfferPDF from '@salesforce/apex/OpportunityUnitSearchController.sendSalesOfferPDF';
import sendAssignRequestEmail from '@salesforce/apex/OpportunityUnitSearchController.sendAssignRequestEmail';
import getsObjectType from '@salesforce/apex/OpportunityUnitSearchController.getsObjectType';
import createInstallmentLineChanges from "@salesforce/apex/InstallmentLineChangesService.createInstallmentLineChanges";
import createBookingMemo from "@salesforce/apex/BookingMemoService.createBookingMemo";
import lastCreatedIdBookingMemo from "@salesforce/apex/BookingMemoService.lastCreatedIdBookingMemo";
import performBudgetCheck from "@salesforce/apex/OpportunityUnitSearchController.performBudgetCheck";
import unitFinishingValues from "@salesforce/apex/OpportunityUnitSearchController.unitFinishingValues";
import unitFurnishingValues from "@salesforce/apex/OpportunityUnitSearchController.unitFurnishingValues";
import getUserStatus from "@salesforce/apex/OpportunityUnitSearchController.getUserStatus";
import mortgageApplicableValues from "@salesforce/apex/OpportunityUnitSearchController.mortgageApplicableValues";
import mortgageBankValues from "@salesforce/apex/OpportunityUnitSearchController.mortgageBankValues";
import getWinReasonPickList from "@salesforce/apex/OpportunityUnitSearchController.getWinReasonPickList";
import signatureTypes from "@salesforce/apex/OpportunityUnitSearchController.signatureTypes";
import uploadFile from '@salesforce/apex/OpportunityUnitSearchController.uploadFile'

import getProjectToProjectBudget from "@salesforce/apex/OpportunityUnitSearchController.getProjectToProjectBudget";

import insertMemoLines from "@salesforce/apex/MemoLinesService.insertMemoLines";
import createMemoLines from "@salesforce/apex/MemoLinesService.createMemoLines";
import getOfferLinesQuery from "@salesforce/apex/OfferLinesService.getOfferLinesQuery";
import getVFDomainURL from "@salesforce/apex/Utilities.getVFDomainURL";
import documentReparent from "@salesforce/apex/Utilities.documentReparent";
import getRegistrationValidation from '@salesforce/apex/OpportunityUnitSearchController.validateRegistrationAllowed';
import reserveUnit from '@salesforce/apex/OpportunityUnitSearchController.reserveUnit';
import lockUnits from '@salesforce/apex/OpportunityUnitSearchController.lockUnits';
import lightningdatatableHideColumn from '@salesforce/resourceUrl/lightningdatatableHideColumn'
import getConstant from '@salesforce/apex/Utilities.getConstant';
import MemoDirectCommission from '@salesforce/label/c.MemoDirectCommission';
import MemoIndirectCommission from '@salesforce/label/c.MemoIndirectCommission';
import ADHAProject from '@salesforce/label/c.ADHAProject';
import Excempted_Project from '@salesforce/label/c.Excempted_Project';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import { NavigationMixin } from 'lightning/navigation';
import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import {getRecord,getRecordNotifyChange} from 'lightning/uiRecordApi';
import {loadStyle} from 'lightning/platformResourceLoader'
import getMandatoryDocs from '@salesforce/apex/SalesOrderService.getMandatoryDocs';
import checkSMAuthorizationForBooking from "@salesforce/apex/OpportunityUnitSearchController.checkSMAuthorizationForBooking";
import getProjectCurrency from "@salesforce/apex/OpportunityUnitSearchController.getProjectCurrency";
import getProjectCurrencyfromUnit from "@salesforce/apex/OpportunityUnitSearchController.getProjectCurrencyfromUnit";
import getAssignedUnitsCount from "@salesforce/apex/OpportunityUnitSearchController.getAssignedUnitsCount";
import MaxAllowedUnitsToAssign from '@salesforce/label/c.MaxAllowedUnitsToAssign';//Mahidhar SSC-372
import releaseUnits from "@salesforce/apex/OpportunityUnitSearchController.releaseUnits";
import WarningMessageOnRelaseUnit from '@salesforce/label/c.WarningMessageOnRelaseUnit';
import loggedInUserId from '@salesforce/user/Id';
import getUnitToOfferMap from '@salesforce/apex/OpportunityUnitSearchController.getUnitToOfferMap';

var actions = [
    {label: 'Delete', name: 'delete'}
];

const columns = [
    { label: 'Installment #', fieldName: 'InstallmentNumber',initialWidth: 180},
    { label: 'Milestone', fieldName: 'Milestone', editable: true },
    { label: 'Proposed Installment %', fieldName: 'ProposedInstallmentPercentage', editable: true },
    { label: 'Broker Payout %', fieldName: 'ProposedBrokerPercentage', editable: true },
    {
        label: 'Proposed Installment Date', fieldName: 'ProposedInstallmentDate', type: 'date', editable: true,
        typeAttributes: {
            year: 'numeric',
            month: 'numeric',
            day: 'numeric',
        }
    },
    {type: 'action', typeAttributes: { rowActions: actions } } 
];

export default class OpportunityUnitSearch extends NavigationMixin(LightningElement) {
    //Get Opportunity or Lead Ids
    label = {
        MemoDirectCommission,
        MemoIndirectCommission
    };
    redirecPageUrl;
    memoIndirectCommissionAlert = 'Int Commission Percentage should be between 0% and ' + MemoIndirectCommission +'%';
    memoDirectCommissionAlert = 'Broker Commission Percentage should be between 0% and ' + MemoDirectCommission +'%';
    showBudgetModal=false;
    @track columns = columns;
    @track sortBy;
    @track sortDirection;
    @track dataInstallmentLineChanges = [];
    @api recordId;
    unitFinishingVals;
    podiumChoices = [
        {label: '--None--', value: ''},
        {label: 'Kitchen', value: 'Kitchen'},
        {label: 'Multi Purpose Room', value: 'Multi Purpose Room'}
    ];

    defaultCurrency;
    unitFurnishingVals
    mortgageApplicableVals;
	signatureTypesVals;
    mortgageBankVals;
    sObjectRecord;
    sObjectRecordType;
    steps=[];
    attachedFiles = [];
    membershipValues =[];
    voucherValues =[];
    unitsToLock=[];
    unitsSelectedList=[];
    pageNumber=1;
    @track
    selectedUnits={};
    isExport=false
    isLoading=true;
    projectList;
    selectedProject;
    buildingList;
    selectedBuilding;
    buildingToPaymentMap={};
    selectedPaymentOptions=[];
    amountValues=[];
    currentUnit;
    propertyUsageList;
    unitTypesSetList;
    unitModelSetList;
    floorNumberSetList;
    unitBedRoomsSetList;
    winReasonOptions;
    projectRecord;
    unitViewSetList;
    currentOffer;
    disableDownload;
    lastCreatedBookingMemoId;
    availableEOIs;
    @track
    unitDataTable;
    unitInventoryDetails;
    registrationValidationMessage='Not Allowed';
    selectedAction;
    fullUrl=''; //modify by Nikhil (LAS-35)
    customerName='Customer';
    pageNumber=1;
    unitAddonParams='';

    

    @track memoFlow = false;
    @track hidePill = false;
    @track reserveMemoFlowButton = false;
    @track reserveFlowButton = false;
    @track reserveFlow = false;
    @track reserveBookingFlow = false;
    @track exportExcel = false;
    @track prfName;
    isBlocked = false;
    blockedMessage;
    isReleaseButtonDisable = false;
    showTooltip=false;
    userId = strUserId;
    unitToOfferMap;
    reservationPaymentMethod;//added by Nikhil LAS-71

    // ======= START: Added by Nikhil (LAS-59)
    applyPercentageAmountOptions = [
        {label: 'Percentage', value: 'Percentage'},
        {label: 'Amount', value: 'Amount'}
    ];
    applyPercentageAmount = 'Percentage';
    // ======= END: Added by Nikhil (LAS-59)

    /* Default methods */
    connectedCallback(){
        //this.getUrStatus();
		this.checkSMAuthorization();
    if(!this.isBlocked){
      this.gesObjectData();
    }
       
    }

    get isReleaseButtonDisabled() {
        return (this.disableOffer || (this.isReleaseButtonDisable));
    }

    
    get releaseUnitValidationMessage() {
       return this.isReleaseButtonDisable ? WarningMessageOnRelaseUnit : ``
    }


    getUrStatus() {
        getUserStatus()
        .then(data=>{
           this.isBlocked = data;
        }).catch(error => { 
           
        });
    }
       checkSMAuthorization(){
        checkSMAuthorizationForBooking({recordId :this.recordId })
        .then(data=>{
            this.isBlocked = data.isBlocked;
            this.blockedMessage = data.blockedMessage;
            
        }).catch(error => { 
           
        });
    }
    renderedCallback(){
        if(this.isExport){
            this.startDownload();
            this.isExport=false;
        }
        if(this.populateSelectedValsFlag){
            console.log('insdie renderedcallback');
            this.populateSelectedVals();
            
        }

        if(this.isCssLoaded) return
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
    @wire(getProjectCurrency, { projectId: '$selectedProject' })
    wiredData({ error, data }) {
      if (data) {
        console.log('Data', data);
        this.defaultCurrency = data;
      } else if (error) {
         console.error('Error:', error);
      }
    }
    
    @wire(getProjectCurrencyfromUnit, { recordId: '$recordId' })
    wiredDataunit({ error, data }) {
      if (data) {
        if(data!= ''){
            console.log('Data', data);
            this.defaultCurrency = data;
        }
      } else if (error) {
         console.error('Error:', error);
      }
    }

    disconnectedCallback(){
        
    }
    
    get ICACheckRequired(){
        return (this.sObjectRecord && this.sObjectRecord.CustomerResidentStatus__c && this.sObjectRecord.CustomerResidentStatus__c==='Non-Resident');
    }
    /* getters */
    get disablPath(){
        return (this.pageNumber==1 || this.steps==[]);
    }
    get paymentOptionsForReservation() {
        // Removed Wire Transfer Value as part of ASF-3637
      //modify by Nikhil LAS-71
       return !this.reservationPaymentMethod || this.reservationPaymentMethod.trim() === ''?
        [
            { label: 'Online', value: 'Online' },
            { label: 'POS', value: 'POS' },
            { label: 'NA', value: 'NA'},
        ]:
        this.reservationPaymentMethod.split(';').map(item => ({
                label: item,
                value: item
                }));
    }
    get paymentAmountOptionsForReservation() {
       // Removed two Values as part of ASF-3637
        return [
            { label: 'Default Amount', value: 'Default Amount' },
        ];
    }
    get saleOfferInputParam(){
        var param1_unitToOfferMap = [];
        for(var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus){
                let selectedPayments = []; 
                if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated ){
                    for(let i = 0 ; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                        if(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                            selectedPayments.push(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id);
                        }
                    }
                }

                let unitAddonValueList = [];
                
            //     //   console.log('Param - podiumselected');
            //     if(this.selectedUnits[key].UnitAddonList){
            //         var unitmap = this.selectedUnits[key].UnitAddonList;
                
            //     for(var key in unitmap){
            //         unitAddonValueList.push({key:key,value:unitmap[key]});
            //     }
            // }
            
            console.log(this.selectedUnits[key].UnitAddonList);
                let tempUnitSelectionObj = {'unitId':key,
                                            'offerId':this.selectedUnits[key].offerId,// (this.currentUnit == key ? this.currentOffer : undefined),
                                            'designId':this.selectedUnits[key].unitDesignRecordId,
                                            'selectedPayments':selectedPayments,
                                            'amount':this.selectedUnits[key].reservationAmount,
                                            'amountType':this.selectedUnits[key].reservationAmountType,
                                            'paymentMethod':this.selectedUnits[key].paymentMethod,
                                            'multiPurposeAmountApplicable': (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable )?this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable:false ,
                                            'podiumselection': this.selectedUnits[key].podiumSelection,
                                            //swimming pool related changes for yas riva
                                            'swimmingPoolSelection': this.selectedUnits[key].swimmingPoolSelection, 
                                            'unitFinishes':this.selectedUnits[key].unitFinishes,
                                            'UnitAddonList': this.selectedUnits[key].UnitAddonList,
                                            'unitFurnishing': this.selectedUnits[key].unitFurnishing,
                                            'mortgageApplicable':this.selectedUnits[key].mortgageApplicable,
                                            'mortgageBank':this.selectedUnits[key].mortgageBank,
											'signatureType': (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.signatureType) ? this.selectedUnits[key].salesOfferDetails.signatureType : null
                                            };
                //console.log(tempUnitSelectionObj);
                param1_unitToOfferMap.push(tempUnitSelectionObj);
            }
            
        }
        console.log(param1_unitToOfferMap);
        return param1_unitToOfferMap;
    }
    get disableProceed(){
        return ((this.OfferWizard || this.ReservationWizard || this.BookingWizard) && this.pageNumber==3) ; 
    }
    get disableBack(){
        return (this.OfferWizard && this.pageNumber==2 && this.sObjectRecordType == 'Unit__c');
    }
    get disableOffer(){
        return (this.totalSelectedUnits < 1);
    }
    get disableMemo(){
        return (this.totalSelectedUnits < 1 /*|| this.totalSelectedUnits > 1*/);
    }
    get disableReleaseUnit() {
        return (this.totalSelectedUnits < 1 || (this.releaseUnitValidationMessage != undefined && this.releaseUnitValidationMessage != null && this.releaseUnitValidationMessage != ''));
    }

    get disableReserve() {
        return (this.totalSelectedUnits < 1 || (this.registrationValidationMessage != undefined && this.registrationValidationMessage != null && this.registrationValidationMessage != ''));
    }

    get disableBooking() {
        return (this.totalSelectedUnits < 1 || (this.registrationValidationMessage != undefined && this.registrationValidationMessage != null && this.registrationValidationMessage != ''));
    }
    get showPage1(){
        return this.pageNumber==1;
    }
    get showPage2(){
        return this.pageNumber==2
    }
    get showPage3(){
        return this.pageNumber==3
    }
    get unitWizard(){
        return (this.sObjectRecordType == 'Unit__c');
    }
    get OfferWizard(){
        return (this.selectedAction == 'OFFER');
    }
    get ReservationWizard(){
        return (this.selectedAction == 'RESERVE');
    }
    get BookingWizard(){
        return (this.selectedAction == 'BOOKING');
    }
    get MemoWizard(){
        return (this.selectedAction == 'MEMO');
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
    get budgetCheckProfileAllowed() {
        return (this.prfName == 'System Administrator' || this.prfName == 'Sales Manager' )
    } 

    get isPostSalesProfile() {
        return this.prfName == 'Customer Management - D&T' ? true : false;
    }
    
    get totalSelectedUnitProject(){
        var selectedCountToReturn=0;
        const filteredUnitsProjects = this.selectedUnitList.reduce((acc, current) => {
            const x = acc.find(item => item.ProjectName === current.ProjectName);
            if (!x) {
              return acc.concat([current]);
            } else {
              return acc;
            }
        }, []);
        selectedCountToReturn= filteredUnitsProjects.length;
        return selectedCountToReturn;
    }

    get selectedUnitPaymentList(){
        let unitsToReturn = [];
        for(var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus){
                unitsToReturn.push(this.selectedUnits[key]);
            }
        }
        return unitsToReturn;
    }
    disableBookingButton=true;
    tempButtonCheck(){
    }
    fileData;
    handleBookingButtonDisplay(event){
        if(event.target.files){
            const file = event.target.files[0]
            var reader = new FileReader()
            reader.onload = () => {
                var base64 = reader.result.split(',')[1]
                this.fileData = {
                    'filename': file.name,
                    'base64': base64,
                    'recordId': this.recordId
                }
                this.isLoading=true;
            }

            reader.onloadend = () => {
                this.isLoading=false;
                if(this.template.querySelector(".bookingConfirmationWinReason") && this.template.querySelector(".bookingConfirmationWinReason").value && this.template.querySelector(".bookingConfirmationConfirm") && this.template.querySelector(".bookingConfirmationConfirm").checked && (!this.ICACheckRequired || this.fileData ) ){
                    this.disableBookingButton= false;
                }else{
                    this.disableBookingButton= true;
                }
            }

            reader.readAsDataURL(file);
        }
        if(this.template.querySelector(".bookingConfirmationWinReason") && this.template.querySelector(".bookingConfirmationWinReason").value && this.template.querySelector(".bookingConfirmationConfirm") && this.template.querySelector(".bookingConfirmationConfirm").checked && (!this.ICACheckRequired || this.fileData ) ){
            this.disableBookingButton= false;
        }else{
            this.disableBookingButton= true;
        }
    }

    navigateToBookingMemoRecord() {

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.lastCreatedBookingMemoId,
                objectApiName: 'BookingMemo__c',
                actionName: 'view'
                
            }
        });
    }
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

    @wire(unitFinishingValues)
    getunitFinishingValues({ error, data }) {
        if (data) {
            this.unitFinishingVals = data;
            
        } else if (error) {
            this.unitFinishingVals = undefined;
        }
    }

    @wire(unitFurnishingValues)
    getUnitFurnishingValues({ error, data }) {
        if (data) {
            this.unitFurnishingVals = data;
            
        } else if (error) {
            this.unitFurnishingVals = undefined;
        }
    }

    @wire(mortgageApplicableValues)
    getmortgageApplicableValues({ error, data }) {
        if (data) {
            this.mortgageApplicableVals = data;
            
        } else if (error) {
            this.mortgageApplicableVals = undefined;
        }
    }
    getSignatureTypes(){
        signatureTypes({projectId :this.selectedProject })
        .then(data => {
            if(data.length >0){
            this.signatureTypesVals = data;
        }else {
            this.signatureTypesVals = undefined;
        }
        })
        .catch(error => {
            this.signatureTypesVals = undefined;
        });
    }
    @wire(mortgageBankValues)
    getmortgageBankValues({ error, data }) {
        if (data) {
            this.mortgageBankVals = data;
            
        } else if (error) {
            this.mortgageBankVals = undefined;
        }
    }

    @wire(getWinReasonPickList)
    getWinReasonValues({ error, data }) {
        if (data) {
            this.winReasonOptions = data;
            
        } else if (error) {
            this.winReasonOptions = undefined;
        }
    }

    get acceptedFormats() {
        return ['.pdf', '.png','.jpg','.jpeg'];
    }

    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.showBudgetModal = true;
    }
    closeModal(event) {
        // to close modal set isModalOpen tarck value as false
        //this event has been fired from the modal component it self
        this.showBudgetModal = event.detail.isOpen;
    }
    @track uploadedFileNames=[];
    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        this.uploadedFileNames = [];
        for(let i = 0; i < uploadedFiles.length; i++) {
            this.uploadedFileNames.push({'name':event.detail.files[i].name , 'documentId':event.detail.files[i].documentId } );
            this.attachedFiles.push(uploadedFiles[i].documentId);
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: uploadedFiles.length + ' Files uploaded Successfull',
                variant: 'success',
            }),
            
        );
    }

    handleAttachmentRemove(event){
        var tempFiles = [];
        this.attachedFiles=[];
        for (let i = 0; i < this.uploadedFiles.length; i++) {
            if(event.target.name != this.uploadedFileNames[i].documentId){
                tempFiles.push({'name':this.uploadedFileNames[i].name , 'documentId':this.uploadedFileNames[i].documentId } );
                this.attachedFiles.push(this.uploadedFileNames[i].documentId);
            }
        }
        this.uploadedFileNames = tempFiles;
    }

    async memoForward(){


        for(var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus){

                let pd = JSON.parse(JSON.stringify(this.selectedUnits[key]));
                //Check Net Impact
                if(pd.netOfferValueField ==null || pd.netOfferValueField == undefined || pd.netOfferValueField ==0 ){
                    const evt = new ShowToastEvent({
                        title: 'Net Impact',
                        message: pd.unitName + ': Invalid Net Impact value' ,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading=false;
                    return;
                }
                if (Number(pd.netOfferValueField/pd.salesOfferDetails.unitRecord.SellingPrice__c *100 ) > 50) {
                    const evt = new ShowToastEvent({
                        title: 'Net Impact',
                        message: pd.unitName + ': Summation for all percentage fields should not be more than 50%',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading=false;
                    return;
                }
                //Verify the 100% 
                if(pd.dataInstallmentLineChanges.length > 0 ){
                    let percentageTotal= 0;
                    let payoutPercentageTotal= 0;
                    for (let i = 0; i < pd.dataInstallmentLineChanges.length; i++) {
                        percentageTotal += Number(pd.dataInstallmentLineChanges[i].ProposedInstallmentPercentage);
                        payoutPercentageTotal += pd.dataInstallmentLineChanges[i].ProposedBrokerPercentage ? Number(pd.dataInstallmentLineChanges[i].ProposedBrokerPercentage):0;
                    }
                    if(Number(percentageTotal) != 100 ){
                        const evt = new ShowToastEvent({
                            title: 'Installment Lines',
                            message: pd.unitName + ': Installment percentage must sum up to 100%',
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                        this.isLoading=false;
                        return;
                    }else if(Number(payoutPercentageTotal) != 100){
                        const evt = new ShowToastEvent({
                            title: 'Installment Lines',
                            message: pd.unitName + ': Broker Payout percentage must sum up to 100%',
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                        this.isLoading=false;
                        return;
                    }
                }

            }   
        }
       
        

        //Required fields
        if (this.memoHeaderField!=undefined && this.memoHeaderField!=null && this.memoHeaderField!='' && this.memoSubjectField!=undefined && this.memoSubjectField!=null && this.memoSubjectField!='' && this.memoTypeField!=undefined && this.memoTypeField!=null && this.memoTypeField!=''){
            
                //this.createBookingMemo();

                this.lastCreatedBookingMemoId = await createBookingMemo({relatedOpportunity: this.recordId , memoHeader: this.memoHeaderField ,memoSubject: this.memoSubjectField, memoType: this.memoTypeField, specialNote: this.specialNoteField});
                //var memoLinesArray = [];
                //this.lastCreatedBookingMemoId = await lastCreatedIdBookingMemo();
                let recordsToCreate =[];
                let installmentRecordsToCreate = [];
                for(var key in this.selectedUnits){
                    if(this.selectedUnits[key].selectionStatus){
                        //console.log(this.selectedUnits[key]);
                        recordsToCreate.push({
                            BookingMemo__c : this.lastCreatedBookingMemoId,
                            Unit__c : key,
                            ExistingOffer__c : this.selectedUnits[key].offerId,
                            ExistingPaymentPlan__c : this.selectedUnits[key].paymentPlanId,
                            SCWaiverYears__c : this.selectedUnits[key].sCWaiverYearsField ? Number(this.selectedUnits[key].sCWaiverYearsField) : undefined,
                            PMFeeYears__c : this.selectedUnits[key].pMFeeYearsField ? Number(this.selectedUnits[key].pMFeeYearsField) :undefined,
                            HomeMaintenanceYears__c : this.selectedUnits[key].homeMaintenanceYearsField ? Number(this.selectedUnits[key].homeMaintenanceYearsField) :undefined,
                            SubsidyPercentage__c :this.selectedUnits[key].subsidyPercentageField ?  Number(this.selectedUnits[key].subsidyPercentageField) :undefined,
                            DiscountPercentage__c :this.selectedUnits[key].discountPercentageField ? Number(this.selectedUnits[key].discountPercentageField) :undefined,
                            RebatePercentage__c : this.selectedUnits[key].rebatePercentageField ? Number(this.selectedUnits[key].rebatePercentageField) :undefined,
                            IntCommissionPercentage__c :this.selectedUnits[key].intCommissionPercentageField? Number(this.selectedUnits[key].intCommissionPercentageField) :undefined,
                            BrokerCommissionPercentage__c :this.selectedUnits[key].brokerCommissionPercentageField ? Number(this.selectedUnits[key].brokerCommissionPercentageField) :undefined,
                            ADMFeePercentage__c : this.selectedUnits[key].aDMFeePercentageField ? Number(this.selectedUnits[key].aDMFeePercentageField) :undefined,
                            VoucherName__c : this.selectedUnits[key].voucherNameField ,
                            VoucherAmount__c : this.selectedUnits[key].voucherAmountField ? Number(this.selectedUnits[key].voucherAmountField) :undefined,
                            MembershipType__c : this.selectedUnits[key].membershipTypeField,
                            MembershipAmount__c : this.selectedUnits[key].membershipAmountField ? Number(this.selectedUnits[key].membershipAmountField):undefined,
                            CurrencyIsoCode : this.selectedUnits[key].CurrencyIsoCode, // added by Nikhil (LAS-59)
                            Discount_Value_Type__c : this.selectedUnits[key].discountValueType?this.selectedUnits[key].discountValueType:'Percentage'  // added by Nikhil (LAS-59)
                        });

                        for (let i = 0; i < this.selectedUnits[key].dataInstallmentLineChanges.length; i++) {
                                installmentRecordsToCreate.push({ 
                                                        Unit__c:key,
                                                        PaymentPlan__c: this.selectedUnits[key].paymentPlanId,
                                                        BookingMemo__c: this.lastCreatedBookingMemoId,
                                                        InstallmentNumber__c : (i+1),
                                                        ProposedInstallmentDate__c: this.selectedUnits[key].dataInstallmentLineChanges[i].ProposedInstallmentDate ,
                                                        Description__c: this.selectedUnits[key].dataInstallmentLineChanges[i].Milestone,
                                                        ProposedInstallmentPercentage__c: Number(this.selectedUnits[key].dataInstallmentLineChanges[i].ProposedInstallmentPercentage),
                                                        BrokerPayoutPercentage__c: Number(this.selectedUnits[key].dataInstallmentLineChanges[i].ProposedBrokerPercentage),
                                 });
                        }
                    }
                }
            console.log(recordsToCreate);
            console.log(installmentRecordsToCreate);
            await insertMemoLines({memoLinesList: recordsToCreate , installmentLineChange: installmentRecordsToCreate });
            await documentReparent({documentIds: this.attachedFiles, newEntityId: this.lastCreatedBookingMemoId})
            
            this.isLoading=false;
            
            this.navigateToBookingMemoRecord();
            }else{
                const evt = new ShowToastEvent({
                    title: 'Mandatory Fields',
                    message: 'Kindly make sure to fill mandatory fields. ',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                this.isLoading=false;
            }

    }
    
    async handleMenuAction(event){
        if (this.isPostSalesProfile && this.totalSelectedUnits > 1) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select only one Unit.',
                    variant: 'error',
                }),
            );
            return;
        }
        console.log('handle menu action');
        if(event.target.name=='OFFER'){
            this.selectedAction=event.target.name;
            this.memoFlow= false;
            this.hidePill = false;
            this.reserveFlow = false;
            this.reserveBookingFlow = false;
            this.steps=[]
            this.steps.push({ label: 'Unit Selection', value: 1 });
            this.steps.push({ label: 'Payment and Offer Selection', value: 2 });
            this.steps.push({ label: 'Offer generation', value: 3 });
            this.pageNumber = this.pageNumber+1;
            this.reserveMemoFlowButton = false;
        }else if(event.target.name=='BACK'){
            this.pageNumber = this.pageNumber-1;
            this.reserveMemoFlowButton = false;
                this.reserveFlowButton = false;
            if(this.pageNumber == 1){
                this.clearStatisFilters();
                this.handleFilterChange();
            }
        }else if(event.target.name == 'FORWARD'){
            //budget check
            this.disableBookingButton= true;
            this.isLoading=true;
            if((this.ReservationWizard || this.BookingWizard) && !(await performBudgetCheck({saleOfferInputParam : this.saleOfferInputParam  , opportunityId : this.recordId  }))){
                const evt = new ShowToastEvent({
                    title: 'Budget Check Failed',
                    message: 'Budget Check Failed',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                this.isLoading=false;
                return;
            }

            console.log('trying');



            for(var key in this.selectedUnits){
                if(this.selectedUnits[key].selectionStatus){
                    var selectedPaymentPlanCounter = 0;
                    var selectedOfferCounter = 0;
                    var selectedPODCounter = 0;
                     // swimming related changes for yas riva
                     var selectedSwimmingPoolCounter = 0;
                    var selectedUnitFinishCounter = 0;
                    var selectedUnitDesigncouter = 0

                    console.log('this.selectedUnits[key]');
                  //Unit finish check --- 
                    if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.unitRecord.BuildingSectionName__r.EligibleforUnitFinishes__c 
                        && (this.OfferWizard || this.ReservationWizard || this.BookingWizard) ){
                        // unitFinishes
                            // unitRecord.BuildingSectionName__r.EligibleforUnitFinishes__c
                            console.log('this.selectedUnits[key].salesOfferDetails.unitFinishes');
                            console.log(this.selectedUnits[key].unitFinishes);
                        
                            if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].unitFinishes == undefined){
                                    
                                const evt = new ShowToastEvent({
                                    title: 'Unit Finishing is mandatory. ',
                                    message: 'Kindly select the Unit Finishing for ' + this.selectedUnits[key].salesOfferDetails.unitRecord.Name  + ' Unit' ,
                                    variant: 'error',
                                });
                                this.dispatchEvent(evt);
                                this.isLoading=false;
                                return;
    
    
                                selectedUnitFinishCounter++;
                            }
                        }
                        if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.unitAddons.length >0){
                                if( this.selectedUnits[key].UnitAddonList == null || this.selectedUnits[key].UnitAddonList == undefined ){
                                    for(var i=0;i<this.selectedUnits[key].salesOfferDetails.unitAddons.length;i++){     
                                        const evt = new ShowToastEvent({
                                            title: 'Unit Addons is mandatory. ',
                                            message: 'Kindly select the '+this.selectedUnits[key].salesOfferDetails.unitAddons[i].UnitAddonName+' for ' + this.selectedUnits[key].salesOfferDetails.unitRecord.Name  + ' Unit' ,
                                            variant: 'error',
                                        });
                                        this.dispatchEvent(evt);
                                        this.isLoading=false;
                                        return;
                                    }
                                }else if((this.selectedUnits[key].UnitAddonList != null && this.selectedUnits[key].salesOfferDetails.unitAddons.length != this.selectedUnits[key].UnitAddonList.length )){
                                    var strlis = [];
                                    for(var i=0;i<this.selectedUnits[key].UnitAddonList.length;i++){
                                        strlis.push(this.selectedUnits[key].UnitAddonList[i].key);
                                    }
                                    for(var i=0;i<this.selectedUnits[key].salesOfferDetails.unitAddons.length;i++){
                                            if(!strlis.includes(this.selectedUnits[key].salesOfferDetails.unitAddons[i].UnitAddonName)){
                                                const evt = new ShowToastEvent({
                                                    title: 'Unit Addons is mandatory. ',
                                                    message: 'Kindly select the '+this.selectedUnits[key].salesOfferDetails.unitAddons[i].UnitAddonName+' for ' + this.selectedUnits[key].salesOfferDetails.unitRecord.Name  + ' Unit' ,
                                                    variant: 'error',
                                                });
                                                this.dispatchEvent(evt);
                                                this.isLoading=false;
                                                return;
                                            }
                                    }
                                }
                        }
                  //POD Check
                    if(this.selectedUnits[key].salesOfferDetails.availablePodiumChoices && this.selectedUnits[key].salesOfferDetails.availablePodiumChoices.length>0){
                        // unitRecord.BuildingSectionName__r.EligibleforUnitFinishes__c
                        if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.PodiumSelection){
                            console.log('this.selectedUnits[key].salesOfferDetails');
                            console.log(this.selectedUnits[key].salesOfferDetails.PodiumSelection);
                            selectedPODCounter++;
                        }
    
                        if(selectedPODCounter!=1 && (this.OfferWizard || this.ReservationWizard || this.BookingWizard)){
                            const evt = new ShowToastEvent({
                                title: 'POD selection is mandatory. ',
                                message: 'POD selection is mandatory for all Units. select None if POD is not required.' ,
                                variant: 'error',
                            });
                            this.dispatchEvent(evt);
                            this.isLoading=false;
                            return;
                        }
                        console.log('selectedPODCounter');
                        console.log(selectedPODCounter);
                    }

                     //swimming pool related changes for yas riva
                     if(this.selectedUnits[key].salesOfferDetails.availableSwimmingPoolChoices && this.selectedUnits[key].salesOfferDetails.availableSwimmingPoolChoices.length>0){
                        if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.swimmingPoolSelection){
                            selectedSwimmingPoolCounter++;
                        }
    
                        if(selectedSwimmingPoolCounter!=1 && (this.OfferWizard || this.ReservationWizard || this.BookingWizard)){
                            const evt = new ShowToastEvent({
                                title: 'Swimming Pool selection is mandatory. ',
                                message: 'Swimming Pool selection is mandatory. select No if Swimming Pool is not required.' ,
                                variant: 'error',
                            });
                            this.dispatchEvent(evt);
                            this.isLoading=false;
                            return;
                        }
                    }
                    
                    //UnitDesign Mandatory for FayAlreeman units. 
                    if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.hasUnitDesign){   
                        console.log('this.selectedUnits[key].salesOfferDetails.unitDesignRecordName', this.selectedUnits[key].salesOfferDetails.unitDesignRecordName);
                        console.log('this.selectedUnits[key].salesOfferDetails.unitDesignRecordName', key,this.selectedUnits[key],this.selectedUnits[key].salesOfferDetails);
                        if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].unitDesignRecordName != undefined){
                            selectedUnitDesigncouter++;
                        }

                        if(selectedUnitDesigncouter!=1 && (this.OfferWizard || this.ReservationWizard || this.BookingWizard)){
                            const evt = new ShowToastEvent({
                                title: 'Unit Design is mandatory. ',
                                message: 'Kindly select the Unit Design for ' + this.selectedUnits[key].salesOfferDetails.unitRecord.Name,
                                variant: 'error',
                            });
                            this.dispatchEvent(evt);
                            this.isLoading=false;
                            return;
                        }
                        console.log('selectedUnitDesigncouter');
                        console.log(selectedUnitDesigncouter);
                    }
                                       
                    //Offer check
                    //offerId
                    if(this.selectedUnits[key].salesOfferDetails){                        
                        if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.offerId != undefined){

                            selectedOfferCounter++;
                        }
    
                        if(selectedOfferCounter!=1 && (this.OfferWizard || this.ReservationWizard || this.BookingWizard)){
                            const evt = new ShowToastEvent({
                                title: 'Offer selection is mandatory. ',
                                message: 'Kindly select the offer for all Units. select Not Applicable if not required.' ,
                                variant: 'error',
                            });
                            this.dispatchEvent(evt);
                            this.isLoading=false;
                            return;
                        }
                        console.log('selectedPODCounter');
                        console.log(selectedPODCounter);
                    }
                    
                    //Payment Plan
                    //------
                    if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated ){
                        for(let i = 0 ; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                            if(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                                selectedPaymentPlanCounter++;
                            }
                        }
                    }
                    if(selectedPaymentPlanCounter!=1 && (this.ReservationWizard || this.BookingWizard)){
                        
                        const evt = new ShowToastEvent({
                            title: 'Invalid Payment Plans Selection',
                            message: 'Please select only 1 payment plan for the '+ this.selectedAction +' process',
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                        this.isLoading=false;
                        return;

                    }else if(selectedPaymentPlanCounter ==0  && this.OfferWizard){
                        const evt = new ShowToastEvent({
                            title: 'Invalid Payment Plans Selection',
                            message: 'Please select atleast 1 payment plan for the '+ this.selectedAction +' process',
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                        this.isLoading=false;
                        return;
                    }
                }
            }
            
            if(this.reserveFlow && this.selectedAction=='RESERVE'){
                
                this.reserveMemoFlowButton = true;
                this.reserveFlowButton = true;
            }else{
                this.reserveMemoFlowButton = false;
                this.reserveFlowButton = false;
            }
            
            this.pageNumber = this.pageNumber+1;
            
            this.isLoading=false;
        }else if(event.target.name == 'FORWARDMEMO'){

            if(this.MemoWizard){
                //Validations
                var isError =false;
                this.template.querySelectorAll('lightning-input').forEach(element => {
                    element.reportValidity();
                    if((element.required && !element.value) || !element.checkValidity() ){
                        isError =true;
                    }
                });
        
                if(isError){
                    const evt = new ShowToastEvent({
                        title: 'Validation Error',
                        message: 'Please correct all validation errors before proceeding.',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                    this.isLoading=false;
                    return;
                }
                this.isLoading=true;
                await this.memoForward();
            }
        }
        else if(event.target.name == 'EXPORT'){
            this.isExport=true;
            
        }else if(event.target.name == 'REQUESTOASSIGN'){
            this.unitsSelectedList=[];
            this.selectedUnitList.forEach(element => {
                this.unitsSelectedList.push(element.unitId);
            });
            if (this.unitsSelectedList.length == 0) {
                const evt = new ShowToastEvent({
                    title: 'Unit Assignment',
                    message: 'Please select at least one unit.',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }
            //Added by Mahidhar SSC-372
            if (this.unitsSelectedList.length > Number(MaxAllowedUnitsToAssign)) {
                const evt = new ShowToastEvent({
                    title: 'Unit Assignment',
                    message: `Maximum of ${MaxAllowedUnitsToAssign} units can be selected to assign`,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                return;
            }
            this.isLoading = true;

    try {
        const assignedUnitsCount = await getAssignedUnitsCount({ unitIds: this.unitsSelectedList });
        if (assignedUnitsCount >= Number(MaxAllowedUnitsToAssign)) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Unit Assignment',
                    message: `Maximum of ${MaxAllowedUnitsToAssign} units can be assigned`,
                    variant: 'error',
                })
            );
            this.isLoading=false;
            return;
        }
    } catch (error) {
        let errorMessage = 'Failed to fetch assigned units count.';
        if (error && error.body && error.body.message) {
            errorMessage = error.body.message;
        }

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Unit Assignment Error',
                message: errorMessage,
                variant: 'error',
            })
        );
        this.isLoading=false;
        return;
    }
            //Mahidhar End
            sendAssignRequestEmail({ unitsSelected: this.unitsSelectedList, opportunityId: this.recordId })
            .then(result => {
                console.log('sending email ', result);
                if (result) {
                    const evt = new ShowToastEvent({
                        title: 'Unit Assignment',
                        message: result,
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                    setTimeout(() => {
                        window.location.reload();
                    }, 3000);
                }
            })
            .catch(error => {
                console.log('sending email failed', error);
                let strt = error.body.message.indexOf(', ');
                let end = error.body.message.lastIndexOf(':');
                this.isLoading=false;
                const evt = new ShowToastEvent({
                    title: 'Unit Assignment',
                    message: error.body.message.substring(strt+1, end),
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            })
            .finally( () => {
                this.isLoading=false;
            });
            
        }else if(event.target.name =='RESERVE' || event.target.name =='BOOKING'){
            this.__selectedEventAction=event.target.name;
             console.log('selectedAction->',this.selectedAction);
            this.unitsSelectedList=[];
            this.__isErrorInCatch=false;
            this.selectedUnitList.forEach(element => {
                this.unitsSelectedList.push(element.unitId);
            });
            const notAssignedUnits = Object.values(this.selectedUnitList)
                .filter(unit => unit.selectionStatus === true && (!unit.assignedtouser || unit.assignedtouser !== loggedInUserId))
                .map(unit => unit.unitName);

            if (notAssignedUnits.length) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Unit Assignment',
                message: `Kindly request the Unit to be assigned to you before proceeding Reserve/Book`,
                        variant: 'error',
                    })
                );
                return;
            }

            this.selectedAction = this.__selectedEventAction;
                var DocMandatory = true;
                var DocMandatoryMessage = 'asdasdad';
                console.log('DocMandatory'  + DocMandatory);

                var result = await getMandatoryDocs({opportunityId : this.recordId })
                console.log('result' + result);
                if (result.requiredDocMissing){
                    DocMandatory = false;
                        DocMandatoryMessage = result.message;
                        console.log('inside');
                        console.log('result.message' + result.message);
                }
               
                console.log('DocMandatory' + DocMandatory);

                if(!DocMandatory) {
                    console.log('DocMandatory' + DocMandatory);
                    const evt = new ShowToastEvent({
                        title: 'Mandatory Document Missing',
                        message: DocMandatoryMessage,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading=false;
                    return;
                }


                var targetEventName= event.target.name;
                this.unitsToLock=[];
                this.selectedUnitList.forEach(element => {
                    this.unitsToLock.push(element.unitId);
                });
                var lockSuccess = await lockUnits({unitIds: this.unitsToLock});
                
                if(lockSuccess != 'Success'){
                    const evt = new ShowToastEvent({
                        title: 'Unit Unavailable',
                        message: lockSuccess,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    return;
                }

                 // Suryapratap: changes starts SSC-385
                if(this.selectedAction =='BOOKING') {
                    getUnitToOfferMap({ opportunityId: this.recordId })
                    .then(result => {
                        this.unitToOfferMap = result;
                    })
                    .catch(error => {
                        console.error('Error fetching Unit to Offer Map:', error);
                    });
                }
                // Suryapratap: Changed Ends
                
                this.isLoading=true;
                this.reserveMemoFlowButton = false;
                this.reserveFlowButton = false;
                this.memoFlow= false;
                this.hidePill = true;
                this.reserveFlow = true;
                this.reserveBookingFlow = true;
                this.steps=[]
                
                this.steps.push({ label: 'Unit Selection', value: 1 });
                this.steps.push({ label: 'Payment and Offer Selection', value: 2 });
                if(this.selectedAction =='RESERVE'){
                    this.steps.push({ label: 'Reserve Unit', value: 3 });
                }else{
                    this.steps.push({ label: 'Book Unit(s)', value: 3 });
                }
                this.pageNumber = this.pageNumber+1;
        }else if(event.target.name =='BOOKING'){
        }else if(event.target.name =='MEMO'){
            this.reserveMemoFlowButton = true;
            this.reserveFlowButton = false;
            this.selectedAction=event.target.name;
            this.memoFlow= true;
            this.hidePill = true;
            this.reserveBookingFlow = false;
            this.reserveFlow = false;
            this.steps=[]
            this.dicrectCommissionUpdate();
            this.populateSelectedVals();
            this.steps.push({ label: 'Unit Selection', value: 1 });
            this.steps.push({ label: 'Booking Memo', value: 2 });
            this.pageNumber = this.pageNumber + 1;
        } else if (event.target.name == 'RELEASEUNIT') {//Added By Mahidhar SSC-373
            const unitsSelectedListToRelease = [];
            this.selectedUnitList.forEach(element => {
                unitsSelectedListToRelease.push(element.unitId);
            });
            if (unitsSelectedListToRelease.length == 0) {
                const evt = new ShowToastEvent({
                    title: 'Unit Assignment',
                    message: 'Please select at least one unit.',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                return;
            }
            this.isLoading = true;
            //we need to pass oppId & unitIds
            try {
                releaseUnits({ unitsSelected: unitsSelectedListToRelease, opportunityId: this.recordId, source : 'SFDC'})
                .then(() => {
                        const evt = new ShowToastEvent({
                            title: 'Unit Released',
                            message: 'Unit released Successfully',
                            variant: 'success',
                        });
                        this.dispatchEvent(evt);
                        setTimeout(() => {
                            window.location.reload();
                        }, 3000);
                })
                .catch(error => {
                    console.log('Error:', error);
                    const evt = new ShowToastEvent({
                        title: 'Please connect Sales Support Team to release this Unit',
                        message: error.body.message,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                })
                .finally(() => {
                    this.isLoading = false;
                });
            }
             catch (error) {
                let errorMessage = 'Failed to fetch released units.';
                if (error && error.body && error.body.message) {
                    errorMessage = error.body.message;
                }

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Unit Release Error',
                        message: errorMessage,
                        variant: 'error',
                    })
                );
                this.isLoading=false;
                return;
            }
            
        }
    }
    startDownload() {
        var htmlBody = this.template.querySelector('table'); 
        var downloadLink = document.createElement("a"); 
        document.body.appendChild(downloadLink);
        downloadLink.href = 'data:application/vnd.ms-excel,'+htmlBody.outerHTML.replace(/ /g, '%20');
        //downloadLink.download = 'ProtocolRequest_'+date+' '+time+'.xls';
        downloadLink.download = this.sObjectRecord.Project__c+'.xls';
        downloadLink.click();
        this.isExport=false;
    }

    async dicrectCommissionUpdate(){
        let MemoDirectCommissionWithBroker = await getConstant({messageName: 'MemoDirectCommissionWithBroker'});
        let MemoDirectCommissionWithoutBroker =  await getConstant({messageName: 'MemoDirectCommissionWithoutBroker'});
        for(var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus){
                let pd = JSON.parse(JSON.stringify(this.selectedUnits[key]));
                let brokerCommissionPercentage;
                if (this.sObjectRecord.BrokerAgencyAccount__c != null) {
                    brokerCommissionPercentage = MemoDirectCommissionWithBroker;
                    pd.intCommissionPercentageField = Number(brokerCommissionPercentage.ConstantValue__c);
                    pd.intCommissionAmountField = Number(pd.unitPrice) * Number(brokerCommissionPercentage.ConstantValue__c) / 100;              
                    this.selectedUnits[key] = pd;
                }
                else{
                    brokerCommissionPercentage = MemoDirectCommissionWithoutBroker;
                    pd.intCommissionPercentageField = Number(brokerCommissionPercentage.ConstantValue__c);
                    pd.intCommissionAmountField = Number(pd.unitPrice) * Number(brokerCommissionPercentage.ConstantValue__c) / 100;              
                    this.selectedUnits[key] = pd;
                }
            }
        }
    }
    
    async addProposedInstallmentLineChanges(){
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        let newTableData =[];
        
        let installmentCount = 1;
        this.proposedInstallmentRateField = (this.proposedInstallmentRateField ==undefined || this.proposedInstallmentRateField == null || this.proposedInstallmentRateField =='' )? '0':this.proposedInstallmentRateField ;
        this.proposedBrokerPayoutField = this.proposedBrokerPayoutField ? this.proposedBrokerPayoutField : 0; 
        
        //Validate input Fields
        if (this.proposedMilestoneField !== '' && this.proposedInstallmentRateField !== '' && this.proposedInstallmentDateField !== '' &&
            this.proposedMilestoneField !== null && this.proposedInstallmentRateField !== null && this.proposedInstallmentDateField !== null &&
            this.proposedMilestoneField !== undefined && this.proposedInstallmentRateField !== undefined && this.proposedInstallmentDateField !== undefined && this.proposedInstallmentRateField!=0 &&
            this.proposedInstallmentNumberField !== undefined && this.proposedInstallmentNumberField !== null && this.proposedInstallmentNumberField !== '') 
            {
                let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
                let percentageTotal= 0;
                let brokerPercentageTotal= 0;
                for (let i = 0; i < pd.dataInstallmentLineChanges.length; i++) {
                    percentageTotal += pd.dataInstallmentLineChanges[i].ProposedInstallmentPercentage? Number(pd.dataInstallmentLineChanges[i].ProposedInstallmentPercentage):0;
                    brokerPercentageTotal += pd.dataInstallmentLineChanges[i].ProposedBrokerPercentage ?Number(pd.dataInstallmentLineChanges[i].ProposedBrokerPercentage):0;
                }
                percentageTotal = percentageTotal + Number( this.proposedInstallmentRateField);
                brokerPercentageTotal = brokerPercentageTotal + ( this.proposedBrokerPayoutField ? Number(this.proposedBrokerPayoutField) :0 );

                if(Number(percentageTotal) > 100 ){
                    const evt = new ShowToastEvent({
                        title: 'Installment Lines',
                        message: 'Installment percentage must sum up to 100%',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }else if(Number(brokerPercentageTotal) > 100){
                    const evt = new ShowToastEvent({
                        title: 'Installment Lines',
                        message: 'Broker Payout percentage must sum up to 100%',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }else{

                    for (let i = 0; i < pd.dataInstallmentLineChanges.length; i++) {
                   
                        if (this.proposedInstallmentNumberField == pd.dataInstallmentLineChanges[i].InstallmentNumber) {
                            installmentCount++;
                            pd.dataInstallmentLineChanges[i].InstallmentNumber = installmentCount;
                            installmentCount++;
                        }else{
                            pd.dataInstallmentLineChanges[i].InstallmentNumber = installmentCount;
                            installmentCount++;
                        }
                        newTableData.push(pd.dataInstallmentLineChanges[i]);
                    }
                    newTableData.push({ Milestone: this.proposedMilestoneField ,InstallmentNumber:this.proposedInstallmentNumberField ,ProposedInstallmentPercentage: this.proposedInstallmentRateField, ProposedBrokerPercentage:(this.proposedBrokerPayoutField ==0 ? undefined : this.proposedBrokerPayoutField), ProposedInstallmentDate: this.proposedInstallmentDateField });
                    pd.dataInstallmentLineChanges = newTableData;
                    this.selectedUnits[this.currentUnit] = pd;
                    this.handleSortData();
                    this.proposedMilestoneField = '';
                    this.proposedInstallmentRateField = '';
                    this.proposedInstallmentDateField = '';
                    this.proposedInstallmentNumberField = '';
                    this.proposedBrokerPayoutField = '';

                }
            }else{
                const evt = new ShowToastEvent({
                    title: 'Missing Fields',
                    message: 'Kindly fill all fields before adding the installment.',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }
    }
        
    draftValues = [];
    handleSave( event ) {
        let newTableData =[];
        //let percentageTotal= 0;

        const updatedFields = event.detail.draftValues;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        for (let i = 0; i <  pd.dataInstallmentLineChanges.length; i++) {
            newTableData.push(pd.dataInstallmentLineChanges[i]);
        }
        for (let i = 0; i <  newTableData.length; i++) {
            for (let j = 0; j < updatedFields.length; j++) {
                if ( newTableData[i].InstallmentNumber == updatedFields[j].InstallmentNumber ) {
                    
                    if (updatedFields[j].ProposedInstallmentPercentage != null) {
                        if (Number(updatedFields[j].ProposedInstallmentPercentage) == 0){
                            newTableData.splice(i, 1);
                            break;
                        }else{
                            newTableData[i].ProposedInstallmentPercentage = updatedFields[j].ProposedInstallmentPercentage ;
                        }
                    }
                    if (updatedFields[j].ProposedInstallmentDate != null) {
                        newTableData[i].ProposedInstallmentDate = updatedFields[j].ProposedInstallmentDate ;
                    }
                    if (updatedFields[j].Milestone != null) {
                        newTableData[i].Milestone = updatedFields[j].Milestone  
                    }
                    if (updatedFields[j].ProposedBrokerPercentage != null) {
                        newTableData[i].ProposedBrokerPercentage = updatedFields[j].ProposedBrokerPercentage ;
                    }
                }
            }
        }

        pd.dataInstallmentLineChanges = newTableData;
        this.selectedUnits[this.currentUnit] = pd;
        // console.log(pd);

        this.handleSortData();
        this.draftValues = [];
    }

    handleRowAction(event) {
        const recId =  event.detail.row;  
        const actionName = event.detail.action.name;  
       
        if ( actionName === 'delete' ) {  
            let newTableData =[];

            let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));

            for (let i = 0; i <  pd.dataInstallmentLineChanges.length; i++) {
                newTableData.push(pd.dataInstallmentLineChanges[i]);
            }
            for (let i = 0; i <  newTableData.length; i++) {
                if (newTableData[i].InstallmentNumber == recId.InstallmentNumber ) {
                    newTableData.splice(i, 1);
                }
            }
            pd.dataInstallmentLineChanges = newTableData;
            this.selectedUnits[this.currentUnit] = pd;
            this.handleSortData();
        }
    }

    gesObjectData(){
        getsObjectType({recordID :this.recordId })
        .then(data => {
            for(var key in data){
                this.sObjectRecordType = key;
                this.sObjectRecord = data[key];
            }
            if(this.sObjectRecordType == 'Opportunity'){
                this.populateProjects();
                this.validateRegistrationEliginility();
                this.voucherMembershipValuesChange();
            }else if(this.sObjectRecordType == 'Unit__c'){
                this.selectedUnits[this.sObjectRecord.Id] = {'selectionStatus':true,
                                                            'unitId': this.sObjectRecord.Id, 
                                                            'unitName':this.sObjectRecord.Name,
                                                            'salesOfferDetails':undefined,
                                                            'ProjectName': this.sObjectRecord.Project__r.Name //added by Nikhil (LAS-35)
                                                            };
                this.pageNumber=2;
                this.selectedAction='OFFER';
            }
            
        })
        .catch(error => {
            this.sObjectRecordType = undefined;
            this.sObjectRecord = undefined;
            this.isLoading=false;
        });
    }

    validateRegistrationEliginility(){
        getRegistrationValidation({opportunityId :this.recordId })
        .then(data => {
            this.registrationValidationMessage=data;
        }).catch(error => {
            this.registrationValidationMessage = 'Not Allowed';
            this.isLoading=false;
        });
    }
    
    populateProjects(){
        getAllProjects()
        .then(data => {
            this.projectList = data;
            for(let i=0;i<data.length; i++){
                if(this.sObjectRecord && this.sObjectRecord.Project__c && data[i].label == this.sObjectRecord.Project__c){
                    this.selectedProject = data[i].value;
                    break;
                }
            }
            if(this.selectedProject){
                this.populateBuildings();
                this.getSignatureTypes();
            }else{
                this.isLoading=false;
            }
            
        })
        .catch(error => {
            this.projectList = undefined;
            this.isLoading=false;
        });
    }
    
    projectToProjectBudget(){
        getProjectToProjectBudget({projectId :this.selectedProject })
        .then(data => {
            this.projectRecord = data;
        })
        .catch(error => {
            this.projectRecord=false;
        });
    }
    populateBuildings(){
        this.projectToProjectBudget();
        console.log('Selected project::'+this.selectedProject);
        getAllBuildings({projectId :this.selectedProject })
        .then(data => {
            this.buildingList = data;
            console.log('data+'+data);
            this.selectedBuilding = (data && data[0] && data[0].value)?data[0].value:'';
            if (this.sObjectRecordType == 'Opportunity' && this.sObjectRecord.ServiceRequest__c != null && this.sObjectRecord.ServiceRequest__r.SwappedUnit__c != null) {
                this.selectedBuilding = this.sObjectRecord.ServiceRequest__r.SwappedUnit__r.BuildingSectionName__c;
                this.winReasonVal = 'Won - Upgrade/Downgrade';
            }

            this.populateUnitData();
            this.isLoading=false;
        })
        .catch(error => {
            this.buildingList = undefined;
            this.isLoading=false;
        });
    }
    sendSalesOfferEmail(event){
        this.isLoading=true;
        var singleUnitIdToSend = event.target.dataset.unitId;
        sendSalesOfferPDF({saleOfferInputParam : this.saleOfferInputParam  , opportunityId : this.recordId ,customerName : this.customerName , singleUnitId : singleUnitIdToSend})
        .then(data => {

            this.isLoading=false;
            const evt = new ShowToastEvent({
                title: 'Email Confirmation',
                message: 'Email have been sent successfully.',
                variant: 'success',
            });
            this.dispatchEvent(evt);
            //redirect to opportunity, once user clicks on send All button
            //Else do not redirect
            if(singleUnitIdToSend == undefined || singleUnitIdToSend ==null || singleUnitIdToSend==''){
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
            this.isLoading=false;
            const evt = new ShowToastEvent({
                title: 'Email Confirmation',
                message: 'Sending email failed.',
                variant: 'error',
            });
            this.dispatchEvent(evt);
            
        });
    }
    reserveSelectedUnit(){
        var winReasonValue = this.template.querySelector(".bookingConfirmationWinReason")? this.template.querySelector(".bookingConfirmationWinReason").value:'';
        var selectedEOI = this.template.querySelector(".eoi")? this.template.querySelector(".eoi").value:'';
        getRecordNotifyChange([{recordId: this.recordId}]);
        reserveUnit({saleOfferInputParam : this.saleOfferInputParam  , opportunityId : this.recordId ,action: this.selectedAction , winReason : winReasonValue ,selectedEOI: selectedEOI})
        .then(data => {
            var tempActionName = (this.selectedAction == 'BOOKING') ? 'Booking':'Reservation';
            if(data && data['result'] && data['result']=='success'){
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Opportunity',
                        actionName: 'view'
                        
                    }
                });
                //Hard Refresh
                setTimeout(() => {
                    window.location.href=this.redirecPageUrl;
                }, 500);
            }else if(data && data['result'] ){
                const evt = new ShowToastEvent({
                    title: tempActionName+' Failed',
                    message: tempActionName+' failed '+ data['result'],
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }else{
                const evt = new ShowToastEvent({
                    title: tempActionName+' Failed',
                    message: tempActionName+' failed '+ data,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }
            this.isLoading=false;

        })
        .catch(error => {
            var tempActionName = (this.selectedAction == 'BOOKING') ? 'Booking':'Reservation';
            const evt = new ShowToastEvent({
                title: tempActionName+' Failed',
                message: tempActionName+ ' failed '+ error.message,
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading=false;
        });
    }
    
    generateOffer(){
        console.log('Chiarg'+JSON.stringify(this.saleOfferInputParam) );
        generateSalesOffer({saleOfferInputParam : this.saleOfferInputParam  , opportunityId : this.recordId  })
        .then(data => {
            this.selectedUnits[this.currentUnit].salesOfferDetails=data[this.currentUnit];
            
            console.log('this.selectedUnits[this.currentUnit].salesOfferDetails ==> ', this.selectedUnits[this.currentUnit].salesOfferDetails);
            //Surya Change Start
            console.log('this.unitToOfferMap => ', this.unitToOfferMap);
            if (
                this.unitToOfferMap &&
                Object.keys(this.unitToOfferMap).length > 0
            ) {
                const allowedOfferId = this.unitToOfferMap[this.currentUnit];
                let details = this.selectedUnits[this.currentUnit].salesOfferDetails;
                if (allowedOfferId) {
                    // Case: current unit is in map → keep only its allowed offer
                    if (details.availableOffers && Array.isArray(details.availableOffers)) {
                        details.availableOffers = details.availableOffers.filter(
                            offer => offer.value === allowedOfferId
                        );
                    }

                    if (details.availableWithMemoOffers && Array.isArray(details.availableWithMemoOffers)) {
                        details.availableWithMemoOffers = details.availableWithMemoOffers.filter(
                        offer => offer.value === allowedOfferId
                        );
                    }
                } else {
                    // Case: current unit not in map → remove any mapped offers, keep the rest
                    const mappedOfferIds = Object.values(this.unitToOfferMap);
                    if (details.availableOffers && Array.isArray(details.availableOffers)) {
                        details.availableOffers = details.availableOffers.filter(
                            offer => !mappedOfferIds.includes(offer.value)
                        );
                    }
                    if (details.availableWithMemoOffers && Array.isArray(details.availableWithMemoOffers)) {
                        details.availableWithMemoOffers = details.availableWithMemoOffers.filter(
                            offer => !mappedOfferIds.includes(offer.value)
                        );
                    }
                }
            }else{
                // unitToOfferMap is empty or null → REMOVE offers containing "Offer & Promotion - SC-"
                
                let details = this.selectedUnits[this.currentUnit].salesOfferDetails;

                if (details.availableOffers && Array.isArray(details.availableOffers)) {
                    details.availableOffers = details.availableOffers.filter(
                        offer => !(offer.label && offer.label.includes('Offer & Promotion - SC-'))
                    );
                }

                if (details.availableWithMemoOffers && Array.isArray(details.availableWithMemoOffers)) {
                    details.availableWithMemoOffers = details.availableWithMemoOffers.filter(
                        offer => !(offer.label && offer.label.includes('Offer & Promotion - SC-'))
                    );
                }
            }
            // Surya Change Ends

            //Iterator to set data for all units
            this.availableEOIs=undefined;
            for(var key in this.selectedUnits){
                if(this.selectedUnits[key].selectionStatus){
                    this.selectedUnits[key].salesOfferDetails=data[key];
                    if(data[key].availableEOIs){
                        this.availableEOIs=data[key].availableEOIs;
                    }
                }
            }

             console.log(data);
            if (this.memoFlow && this.memoOfferChaage) {
                this.handleExistingOfferChange();
                this.memoOfferChaage=false;
            }
            
            this.isLoading=false;
        })
        .catch(error => {
            this.isLoading=false;
        });
    }
    @track isDisabled = false;
    populateUnitData(){
        this.exportExcel = false;
        getUnitDetails({buildingsId :this.selectedBuilding })
        .then(data => {
            this.propertyUsageList = data.propertyUsageList;
            this.unitTypesSetList = data.unitTypesSetList;
            this.unitModelSetList= data.unitModelSetList;
            this.floorNumberSetList= data.floorNumberSetList;
            this.unitBedRoomsSetList= data.unitBedRoomsSetList;
            this.unitViewSetList= data.unitViewSetList;
            // remove the unit from list when related opportunity of unit is not same as opportunity for which we are doing booking.
            this.unitInventoryDetails = data.unitDetailList.filter(unit => !unit.unitDetails.RelatedOpportunity__c || unit.unitDetails.RelatedOpportunity__c === this.recordId);

            this.clearStatisFilters();
            this.handleFilterChange();
            if (this.unitInventoryDetails.length > 0) {
                this.exportExcel = true;
            }else{
                const evt = new ShowToastEvent({
                    title: 'Units',
                    message: 'No unit available for selected filter criteria ',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }
            this.isLoading=false;
            if (this.sObjectRecordType == 'Opportunity' && this.sObjectRecord.ServiceRequest__c != null && this.sObjectRecord.ServiceRequest__r.SwappedUnit__c != null) {
                for(let k=0; k<this.unitInventoryDetails.length; k++){
                    if (this.unitInventoryDetails[k].unitDetails.Id == this.sObjectRecord.ServiceRequest__r.SwappedUnit__c) {
                        this.isDisabled = this.isPostSalesProfile ? true : false;
                        this.selectedUnits[this.sObjectRecord.ServiceRequest__r.SwappedUnit__c] = {
                            'selectionStatus': true,
                            'unitId': this.unitInventoryDetails[k].unitDetails.Id,
                            'unitName': this.unitInventoryDetails[k].unitDetails.Name,
                            'ProjectName': this.unitInventoryDetails[k].unitDetails.ProjectName__c,
                            'sCWaiverFee': this.unitInventoryDetails[k].unitDetails.AnticipatedServiceCharges__c,
                            'pMFee': this.unitInventoryDetails[k].unitDetails.PropertyManagementFee__c,
                            'homeMaintenanceFee': this.unitInventoryDetails[k].unitDetails.HomeMaintenanceFee__c,
                            'unitPrice': this.unitInventoryDetails[k].unitDetails.SellingPrice__c,
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
                    }
                }
            }
        })
        .catch(error => {
            this.isLoading=false;
        });
    }
    /* Handler Methods */
    handleProjectChange(event){
        this.unitDataTable=undefined;
        this.isLoading=true;
        this.selectedProject=event.detail.value;
        this.unitDataTable=undefined;
        //this.selectedUnits={};
        this.populateBuildings();
        this.getSignatureTypes();

    }
    
    handleBuildingChange(event){
        this.unitDataTable=undefined;
        this.isLoading=true;
        this.selectedBuilding=event.detail.value;
        
        this.populateUnitData();
    }    
    clearStatisFilters(){
        let allSearchFields = this.template.querySelectorAll('.unitFilter');
        for(let i = 0; i < allSearchFields.length; i++) {
            allSearchFields[i].value='';
        }
    }
    handleFilterChange(){
        this.unitDataTable=undefined;
        this.disableDownload=true;
        var filteredData=[];
        console.log('this.unitInventoryDetails'+JSON.stringify(this.unitInventoryDetails));
        console.log('this.unitInventoryDetails'+this.unitInventoryDetails);
        if(this.unitInventoryDetails){
            let allSearchFields = this.template.querySelectorAll('.unitFilter');
            for(let k=0; k<this.unitInventoryDetails.length; k++){
                var filerCondition=true;
                for(let i = 0; i < allSearchFields.length; i++) {
                    if(allSearchFields[i].value!=undefined && allSearchFields[i].value!='' ){
                        if(this.unitInventoryDetails[k].unitDetails[allSearchFields[i].dataset.fieldApi] != allSearchFields[i].value){

                            filerCondition= false;
                            break;
                        }
                    }
                }
                if(filerCondition){
                    let tempRec = Object.assign({}, this.unitInventoryDetails[k]);
                    tempRec.isSelected=(this.selectedUnits[tempRec.unitDetails.Id]) ? this.selectedUnits[tempRec.unitDetails.Id].selectionStatus:false;
                    if (this.sObjectRecordType == 'Opportunity' && this.sObjectRecord.ServiceRequest__c != null && this.sObjectRecord.ServiceRequest__r.SwappedUnit__c != null && tempRec.unitDetails.Id == this.sObjectRecord.ServiceRequest__r.SwappedUnit__c) {
                        tempRec.isSelected = true;
                    }
                    filteredData.push(tempRec);
                    this.disableDownload=false;
                }
            }
            
        }
        this.unitDataTable=filteredData;
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
        if(event.target.checked){
            this.selectedUnits[event.target.dataset.id] = {
                'selectionStatus':event.target.checked,
                'unitId': event.target.dataset.id, 
                'unitName': event.target.dataset.unitName,
                'ProjectName': event.target.dataset.unitProject,
                'sCWaiverFee': event.target.dataset.unitAsc,
                'pMFee': event.target.dataset.unitPmf,
                'homeMaintenanceFee': event.target.dataset.unitHmf,
                'unitPrice': event.target.dataset.unitUnitprice,
                'unittype': event.target.dataset.unitUnittype,
                'multipurposeamount': event.target.dataset.unitMultipurposeamount,
                'totalrooms': event.target.dataset.unitTotalrooms,
                'saleablearea': event.target.dataset.unitSaleablearea,
                'measuredarea': event.target.dataset.unitMeasuredarea,
                'terracearea': event.target.dataset.unitTerracearea,
                'onlinereservationfee': event.target.dataset.unitOnlinereservationfee,
                'reservationamount': event.target.dataset.unitReservationamount,
                'intCommissionAmountField': undefined,
                'intCommissionPercentageField': undefined,
                'dataInstallmentLineChanges': [],
                'salesOfferDetails': undefined,
                'assignedtouser': event.target.dataset.unitAssignedtouser
            };
            this.reservationPaymentMethod = event.target.dataset.unitReservationpaymentmethod;//added by Nikhil LAS-71
        }else{
            this.selectedUnits[event.target.dataset.id].selectionStatus=false;
            if (this.totalSelectedUnits < 1) {
                this.memoHeaderField = '';
                this.memoSubjectField = '';
                this.memoTypeField = '';
                this.specialNoteField = '';
            }
        }
        if (this.isPostSalesProfile && this.totalSelectedUnits > 1) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select only one Unit.',
                    variant: 'error',
                }),
            );
        }

        this.isReleaseButtonDisable = Object.values(this.selectedUnits)
            .filter(unit => unit.selectionStatus)
            .some(unit => !unit.assignedtouser || unit.assignedtouser != loggedInUserId);


        this.isLoading = false;
    }

    handlePaymentUnitSelect(event){
        //GET THE OFFERS
        this.isLoading=true;
        this.currentUnit = event.target.value;
        //TODO: PDB gpopulate the UI
        if(!this.selectedUnits[this.currentUnit].salesOfferDetails ){
            this.generateOffer();
        }else{
            this.selectedUnits[this.currentUnit].salesOfferDetails;
        }
        this.populateSelectedValsFlag=true;
    }
    populateSelectedValsFlag=false;
    populateSelectedVals(){
        console.log('Inside populateSelectedVals');
        let selectedOffer = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].selectedOffer");
        let unitFinishingField = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].unitFinishingField");
        let podiumSelectionfi = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].podiumSelectionfi");
        let unitFurnishingField = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].unitFurnishingField");
        let multiPurposeRoomField = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].multiPurposeRoomField");
        let podiumselectedField = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].podiumselectedField");
        // swimmming pool related changes for yas riva
        let swimmingPoolSelectedField = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].swimmingSelectionfi");
        let unitDesiagnField = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].unitDesiagnField");
        let selectedPaymentPlan = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].selectedPaymentPlan");

        let mortgageApplicableField = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].mortgageApplicableField");
        let signatureTypeField = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].signatureTypeField");
        let mortgageBankField = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].mortgageBankField");
        let unitaddonList = this.template.querySelector("[data-record-id='"+ this.currentUnit+"'].unitAddonField");
        //console.log('Chirag11'+JSON.stringify(this.selectedUnits[this.currentUnit].UnitAddonList));
        
        if(unitaddonList){unitaddonList = this.selectedUnits[this.currentUnit].UnitAddonList ;}
        //console.log('Chirag12'+JSON.stringify(unitaddonList));

        if(selectedOffer) {selectedOffer.value=this.selectedUnits[this.currentUnit].offerId ;}
        
        if(unitFinishingField){unitFinishingField.value=this.selectedUnits[this.currentUnit].unitFinishes ;}
                
        if(podiumSelectionfi){
            podiumSelectionfi.value=this.selectedUnits[this.currentUnit].podiumSelection;
        }
        if(unitFurnishingField){unitFurnishingField.value=this.selectedUnits[this.currentUnit].unitFurnishing ;}
        if(mortgageApplicableField){mortgageApplicableField.value= (this.selectedUnits[this.currentUnit].mortgageApplicable==true)?'Yes': (this.selectedUnits[this.currentUnit].mortgageApplicable==false?'No':undefined) ;}
        if(signatureTypeField){signatureTypeField.value = this.selectedUnits[this.currentUnit].salesOfferDetails.signatureType;}
        if(mortgageBankField){mortgageBankField.value=this.selectedUnits[this.currentUnit].mortgageBank ;}

        if(multiPurposeRoomField){ multiPurposeRoomField.checked=this.selectedUnits[this.currentUnit].salesOfferDetails.multiPurposeAmountApplicable;}
        if(podiumselectedField){ podiumselectedField.checked=this.selectedUnits[this.currentUnit].salesOfferDetails.podiumselected;}
        // swimmming pool related changes for yas riva
        if(swimmingPoolSelectedField){ 
            swimmingPoolSelectedField.value=this.selectedUnits[this.currentUnit].swimmingPoolSelection;
            console.log(swimmingPoolSelectedField.value+'==='+JSON.stringify(this.selectedUnits[this.currentUnit]));
        }
        if(unitDesiagnField){unitDesiagnField.value=this.selectedUnits[this.currentUnit].unitDesignRecordId;}


        if((this.ReservationWizard || this.BookingWizard || this.MemoWizard) && selectedPaymentPlan){
            //for reservation wizard if multiple payment are selected then clear selection if one selected then set default
            let selectedPayments = []; 
            if(this.selectedUnits[this.currentUnit].salesOfferDetails && this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated ){
                for(let i = 0 ; i < this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                    if(this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                        selectedPayments.push(this.selectedUnits[this.currentUnit].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id);
                    }
                }
            }
            
            if(selectedPayments.length == 1){
                selectedPaymentPlan.value=selectedPayments[0];
            }else{
                if(selectedPayments.length > 1){
                    //Clear selection
                    let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
                    for(let i = 0 ; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                        pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected = false;
                    }
                    this.selectedUnits[this.currentUnit]=pd;
                }
                selectedPaymentPlan.value='';
            }
        }
        //if ui is refreshed then exit
        if(selectedOffer){
            this.populateSelectedValsFlag=false;
            this.isLoading=false;
        }
        
    }
    unselectPaymentPlan(event){
        
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        for(let i = 0 ; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
            if(pd.salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id == event.target.name){
                pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected= false;
                break;
            }
        }
        this.selectedUnits[this.currentUnit] = pd;
    }
    //selectedPaymentPlan;
    selectPaymentPlan(event){ 
        this.isLoading=true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        if (this.hidePill) {
            for(let i = 0 ; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected = false;
            }
        }

        for(let i = 0 ; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){

            if(pd.salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id == event.target.value){
                pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected= true;
                pd.paymentPlanId=(event.target.value == '') ? undefined : event.target.value;
                break;
            }
        }
        this.selectedUnits[this.currentUnit] = pd;
        this.generateOffer();
    }
    memoOfferChaage=false;
    handleOfferChange(event){
        this.isLoading=true;

        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.offerId=(event.detail.value == '') ? undefined : event.detail.value;
        this.selectedUnits[this.currentUnit] = pd;
        this.memoOfferChaage=true;
        this.generateOffer();
        
    }
    handleDesignChange(event){
        this.isLoading=true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.unitDesignRecordId = (event.detail.value == '') ? undefined : event.detail.value;
        pd.unitDesignRecordName = event.target.options.find(opt => opt.value === event.detail.value).label;
        this.selectedUnits[this.currentUnit] = pd;
        this.generateOffer();
       
    }
    
    async handlePDFActive(event){
        var currentUnit='';
        var currentOffer='';
        var selectedDesign='';
        var otherUnits='';
        var selectedPayments='';
        var multiPurposeAmountApplicable='';
        var PODselection;
        let projectName = '';
         // swimming pool related changes for yas riva
         var swimmingPoolSelection;

        for(var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus){
                if(key == event.target.dataset.unitId){
                    currentUnit=key;
                    console.log("Project Name check>>"+JSON.stringify( this.selectedUnits[key]));
                    projectName = this.selectedUnits[key].ProjectName?this.selectedUnits[key].ProjectName:this.selectedUnits[key].salesOfferDetails.unitRecord.Project__r.Name;//added by Nikhil (LAS-35)
                    if(this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated ){
                        for(let i = 0 ; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                            if(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id && this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                                selectedPayments= selectedPayments+ (selectedPayments==''?'':'|')+ (this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].paymentPlanDetails.Id);
                            }
                        }
                    }
                    multiPurposeAmountApplicable = (this.selectedUnits[key].salesOfferDetails)?this.selectedUnits[key].salesOfferDetails.multiPurposeAmountApplicable:false;
                    currentOffer= (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.offerId)?this.selectedUnits[key].salesOfferDetails.offerId:'' ;
                    selectedDesign= (this.selectedUnits[key].salesOfferDetails && this.selectedUnits[key].salesOfferDetails.unitDesignRecordId)?this.selectedUnits[key].salesOfferDetails.unitDesignRecordId:'' ;
                    PODselection = (this.selectedUnits[key].salesOfferDetails)?this.selectedUnits[key].salesOfferDetails.PodiumSelection:false;
                    // swimming pool related changes for yas riva
                    swimmingPoolSelection = (this.selectedUnits[key].salesOfferDetails)?this.selectedUnits[key].salesOfferDetails.swimmingPoolSelection:false;
                }else{
                    otherUnits= otherUnits + (otherUnits==''?'':'|')+ key;
                }
            }
        }
        
        if(event.target.dataset.targetType == 'input'){
            this.customerName = event.target.value;
        }

        var mainUrl = await getVFDomainURL();
        //added by Nikhil (LAS-35)
        if(projectName.includes("London Square")){
            this.fullUrl = mainUrl + '/apex/OfferDetailsLSQPDF?id='+this.recordId+'&currentUnit='+currentUnit+'&currentOffer='+currentOffer+'&otherUnits='+otherUnits+'&selectedPayments='+selectedPayments+'&customerName='+this.customerName+'&multiPurposeAmount='+multiPurposeAmountApplicable+'&selectedDesign='+selectedDesign+'&PODselection='+PODselection+'&swimmingPoolSelection='+swimmingPoolSelection+this.unitAddonParams;

        }else{
            this.fullUrl = mainUrl + '/apex/OfferDetailsPDF?id='+this.recordId+'&currentUnit='+currentUnit+'&currentOffer='+currentOffer+'&otherUnits='+otherUnits+'&selectedPayments='+selectedPayments+'&customerName='+this.customerName+'&multiPurposeAmount='+multiPurposeAmountApplicable+'&selectedDesign='+selectedDesign+'&PODselection='+PODselection+'&swimmingPoolSelection='+swimmingPoolSelection+this.unitAddonParams;
        }
        //added by Nikhil (LAS-35)
        console.log('this.fullUrl', this.fullUrl);
    }

    handlePaymentMethodChange(event){
        var currentUnit= event.target.name;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[currentUnit]));
        pd.paymentMethod= event.target.value;
        this.selectedUnits[currentUnit] = pd;
    }

    handleUnitFinishesChange(event){
        this.isLoading=true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.unitFinishes= event.target.value;
        console.log('pd.unitFinishes');
        console.log(pd.unitFinishes);
        this.selectedUnits[this.currentUnit] = pd;
        console.log(pd);
        this.generateOffer();
    }
    unitAddonMap = new Map();
    setOrUpdateUnitAddonMap(key, value) {
        this.unitAddonMap.set(key, value); // Adds or updates the key-value pair
    }
    handleUnitAddonChange(event){
        this.isLoading=true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        console.log('Chirag1'+ event.target.value);
        console.log('Chirag2'+ event.target.name);
        
        this.unitAddonParams += '&'+event.target.name+'='+event.target.value;
        this.setOrUpdateUnitAddonMap( event.target.name, event.target.value);
        let mapArray = [];
            if(this.unitAddonMap){
                // Use for...of loop to iterate over the Map
                for (let [key, value] of this.unitAddonMap) {
                    // Push each key-value pair into the array
                    mapArray.push({ key: key, value: value });
                }
            }
         pd.UnitAddonList= mapArray;
        // console.log('pd.unitFinishes');
        // console.log(pd.UnitAddonList);
         this.selectedUnits[this.currentUnit] = pd;
        console.log(pd);
        this.generateOffer();
    }

    handleUnitPodiumChange(event){
        this.isLoading=true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.podiumSelection= event.target.value;
        this.selectedUnits[this.currentUnit] = pd;
        this.generateOffer();
    }

    // swimming pool related changes for yas riva

    handleUnitSwimmingPoolChange(event){
        this.isLoading=true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.swimmingPoolSelection= event.target.value;
        this.selectedUnits[this.currentUnit] = pd;
        this.generateOffer();
    }

    handleUnitFurnishingChange(event){
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.unitFurnishing= event.target.value;
        this.selectedUnits[this.currentUnit] = pd;
    }
    handleMortgageChange(event){
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.mortgageApplicable= (event.target.value == 'Yes' );
        this.selectedUnits[this.currentUnit] = pd;
    }
    handleMortgageBankChange(event){
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        pd.mortgageBank= event.target.value;
        this.selectedUnits[this.currentUnit] = pd;
    }
    handleSignatureTypeChange(event){
       let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit].salesOfferDetails) );
       console.log('pd signature:::'+pd);
       pd.signatureType= event.target.value;
       console.log('pd signature:::'+JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit].salesOfferDetails)));
       this.selectedUnits[this.currentUnit].salesOfferDetails = pd;
    }
    handleMultiPurposeRoomChange(event){
        this.isLoading=true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));

        pd.salesOfferDetails.multiPurposeAmountApplicable= event.target.checked;
        this.selectedUnits[this.currentUnit] = pd;
        this.generateOffer();
    }
    
    handlePodiumChange(event){
        this.isLoading=true;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));

        pd.salesOfferDetails.PodiumSelected= event.target.checked;
        this.selectedUnits[this.currentUnit] = pd;
        this.generateOffer();
    }

    @track homeMaintenanceYearsField;
    @track aDMFeePercentageField;
    @track pMFeeYearsField;
    @track sCWaiverYearsField;

    async handleExistingOfferChange(){

        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        
        var newData=[];
        if(pd.offerId){
            let query = 'SELECT Id,Name,OfferOn__c,OfferType__c,OfferValue__c,VoucherName__c   FROM OfferLines__c WHERE OfferName__c = \'' + pd.offerId + '\'';
            newData = await getOfferLinesQuery({query:query});
        }
        
        pd.homeMaintenanceYearsField = undefined;
        pd.homeMaintenanceAmountField = undefined;
        pd.aDMFeePercentageField = undefined;
        pd.aDMFeeAmountField = undefined;
        pd.sCWaiverYearsField = undefined;
        pd.sCWaiverAmountField = undefined;
        pd.rebatePercentageField = undefined;
        pd.rebateAmountField = undefined;
        pd.pMFeeYearsField = undefined;
        pd.pMFeeAmountField = undefined;
        console.log(pd.salesOfferDetails);
        for (let i = 0; i < newData.length; i++) {
            if (newData[i].OfferOn__c == 'Home Maintenance Fees') {
                pd.homeMaintenanceYearsField = newData[i].OfferValue__c;
                pd.homeMaintenanceAmountField = (pd.salesOfferDetails.unitRecord.BuildingSectionName__r.HomeMaintenanceFee__c && pd.homeMaintenanceYearsField) ? Number(pd.salesOfferDetails.unitRecord.BuildingSectionName__r.HomeMaintenanceFee__c) * Number(pd.homeMaintenanceYearsField) : 0;//await calculateMultiply({ firstValue : Number(pd.homeMaintenanceFee), secondValue: Number(pd.homeMaintenanceYearsField)}); 
            }
            else if (newData[i].OfferOn__c == 'ADM Fees') {
                pd.aDMFeePercentageField = newData[i].OfferValue__c;
                pd.aDMFeeAmountField = Number(pd.salesOfferDetails.unitRecord.SellingPrice__c) * Number(pd.aDMFeePercentageField) / 100; 
            }
            else if (newData[i].OfferOn__c == 'Property Management Fees') {
                pd.pMFeeYearsField = newData[i].OfferValue__c;
                pd.pMFeeAmountField =  (pd.salesOfferDetails.unitRecord && pd.salesOfferDetails.unitRecord.BuildingSectionName__c && pd.salesOfferDetails.unitRecord.BuildingSectionName__r.PropertyManagementFee__c  && pd.salesOfferDetails.unitRecord.MarketLeaseRent__c && pd.pMFeeYearsField)? ( (Number(pd.salesOfferDetails.unitRecord.BuildingSectionName__r.PropertyManagementFee__c)/100) * Number(pd.salesOfferDetails.unitRecord.MarketLeaseRent__c) * Number(pd.pMFeeYearsField) ):0; //await calculateMultiply({ firstValue : Number(pd.pMFee), secondValue: Number(pd.pMFeeYearsField)}); 
            }
            else if (newData[i].OfferOn__c == 'Service Charges') {
                pd.sCWaiverYearsField = newData[i].OfferValue__c;
                if (pd.salesOfferDetails.unitRecord.MeasuredArea__c !== null && pd.salesOfferDetails.unitRecord.MeasuredArea__c !== '' && pd.salesOfferDetails.unitRecord.MeasuredArea__c !== undefined) {
                    pd.sCWaiverAmountField = (( pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c && pd.sCWaiverYearsField)?Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c) * Number(pd.sCWaiverYearsField):0) * pd.salesOfferDetails.unitRecord.MeasuredArea__c;//await calculateMultiply({ firstValue : Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c), secondValue: Number(pd.sCWaiverYearsField)}) * pd.salesOfferDetails.unitRecord.MeasuredArea__c;
                }else{
                    pd.sCWaiverAmountField = ((pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c && pd.sCWaiverYearsField)?Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c) * Number(pd.sCWaiverYearsField) :0) * pd.salesOfferDetails.unitRecord.SaleableArea__c;//await calculateMultiply({ firstValue : Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c), secondValue: Number(pd.sCWaiverYearsField)}) * pd.salesOfferDetails.unitRecord.SaleableArea__c;
                }
            }
            else if (newData[i].OfferType__c == 'Rebate') {
                pd.rebatePercentageField=newData[i].OfferValue__c;
                pd.rebateAmountField = Number(pd.salesOfferDetails.unitRecord.SellingPrice__c) * Number(newData[i].OfferValue__c) / 100; 
            }

        }
        this.selectedUnits[this.currentUnit] = pd;
        if(pd.salesOfferDetails){
            this.netValue();
        }
    }

    async voucherMembershipValuesChange(){
        let newMembershipTableData = [];
        let newVoucherTableData = [];

        let query = 'SELECT Id,Name,OfferOn__c,OfferType__c,OfferValue__c,VoucherName__c FROM OfferLines__c where OfferType__c = \'Voucher\' and OfferName__r.IsActive__c=true';
       
        const newData = await getOfferLinesQuery({query:query});
        newMembershipTableData.push({ label: '--None--' , value: '' , amount: 0 });
        newVoucherTableData.push({ label: '--None--' , value: '' , amount: 0 });

        for (let i = 0; i < newData.length; i++) {
            if (newData[i].OfferType__c == 'Voucher') {
                if (newData[i].OfferOn__c == 'Membership') {
                    if(newData[i].VoucherName__c && newMembershipTableData.findIndex((item) => (item.label === newData[i].VoucherName__c && item.amount === newData[i].OfferValue__c)) === -1 ){
                        newMembershipTableData.push({ label: newData[i].VoucherName__c , value: newData[i].Id , amount: newData[i].OfferValue__c });
                    }
                    
                }else{
                    if (newData[i].VoucherName__c && newVoucherTableData.findIndex((item) => (item.label === newData[i].VoucherName__c && item.amount === newData[i].OfferValue__c)) === -1 ){
                        newVoucherTableData.push({ label: newData[i].VoucherName__c , value: newData[i].Id , amount: newData[i].OfferValue__c });
                    }
                }
            }
        }
        
        this.membershipValues=newMembershipTableData;
        this.voucherValues=newVoucherTableData;
    }

    handleReservationAmountTypeChange(event){
        var currentUnit= event.target.name;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[currentUnit]));
        pd.reservationAmountType= event.target.value;
        if(event.target.value == 'Down Payment'){
            pd.disableAmountInput=true;
            for(let i = 0 ; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                if(pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                    pd.reservationAmount=pd.salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[0].totalValue;
                    break;
                }
            }
        }else if(event.target.value == 'Default Amount'){
            pd.disableAmountInput=true;
            pd.reservationAmount=pd.salesOfferDetails.unitRecord.BuildingSectionName__r.ReservationAmount__c ? pd.salesOfferDetails.unitRecord.BuildingSectionName__r.ReservationAmount__c : pd.salesOfferDetails.unitRecord.Project__r.ReservationAmount__c;
        }else if(event.target.value == 'Custom Amount'){
            pd.disableAmountInput=false;
        }       
        this.selectedUnits[currentUnit] = pd;
    }

    handlePaymentAmountChange(event){
        var currentUnit= event.target.name;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[currentUnit]));
        pd.reservationAmount= event.target.value;
        this.selectedUnits[currentUnit] = pd;
    }
    selectedPaymentCalculatedJS;
    handleReserveChoice(event){
        this.currentUnit = event.target.value;
        var currentUnit= event.target.dataset.unitId;
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[currentUnit]));
        pd.disableAmountInput = (pd.disableAmountInput !=undefined )  ? pd.disableAmountInput : true;
        pd.reservationAmountType=pd.reservationAmountType ? pd.reservationAmountType : '';
        pd.reservationAmount= pd.reservationAmount ? pd.reservationAmount : 0;
        pd.paymentMethod= pd.paymentMethod ? pd.paymentMethod : '';
        this.selectedUnits[currentUnit] = pd;
        for(let i = 0 ; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
            if(pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                this.selectedPaymentCalculatedJS=pd.salesOfferDetails.applicablePaymentPlansCalculated[i];
                break;
            }
        }
        this.populateSelectedValsFlag=true;
    }
    handleReservation(){
        this.isLoading=true;
        if(this.validatePaymentDetails()){
            this.reserveSelectedUnit();
        }
        
    }
    handleBooking(){
        this.isLoading=true;
        //commented by Chirag
        /*for(var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus){
                if(this.selectedUnits[key].mortgageApplicable == undefined){
                    const evt = new ShowToastEvent({
                        title: 'Please select Mortgage applicable',
                        message: 'Please select the Mortgage applicable for '+this.selectedUnits[key].unitName+' before submitting ',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading=false;
                    return false;
                }
                if(this.selectedUnits[key].mortgageApplicable && (this.selectedUnits[key].mortgageBank ==undefined || this.selectedUnits[key].mortgageBank ==null) ){
                    const evt = new ShowToastEvent({
                        title: 'Please select the Mortgage Bank',
                        message: 'Please select the Mortgage Bank for '+this.selectedUnits[key].unitName+' before submitting ',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading=false;
                    return false;
                }
            }
        }*/
        this.reserveSelectedUnit();
        const {base64, filename, recordId} = this.fileData
        uploadFile({ base64, filename, recordId }).then(result=>{
            this.fileData = null
        })
    }
    validatePaymentDetails(){
        for(var key in this.selectedUnits){
            if(this.selectedUnits[key].selectionStatus){
                console.log('RRRRR--->'+this.selectedUnits[key].salesOfferDetails.unitRecord.Project__r.Name);
                if (this.selectedUnits[key].reservationAmount == undefined || ((this.selectedUnits[key].reservationAmount == 0 ) && !Excempted_Project.includes(this.selectedUnits[key].salesOfferDetails.unitRecord.Project__r.Name) && this.selectedUnits[key].salesOfferDetails.unitRecord.Project__r.Name !== ADHAProject) ||
                    this.selectedUnits[key].paymentMethod == undefined || this.selectedUnits[key].paymentMethod == ''){//remove NA condition by nikhil LAS-71
                    const evt = new ShowToastEvent({
                        title: 'Payment Option/Amount not selected',
                        message: 'Please select Payment Method and Amont for '+this.selectedUnits[key].unitName+' before submitting ',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading=false;
                    return false;
                }
                //TODO amount bound check
                if(this.selectedUnits[key].reservationAmountType == 'Custom Amount'){
                    var upperBound=0;
                    for(let i = 0 ; i < this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
                        if(this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected){
                            upperBound=this.selectedUnits[key].salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[0].totalValue;
                            break;
                        }
                    }
                    var lowerBound = this.selectedUnits[key].salesOfferDetails.unitRecord.BuildingSectionName__r.ReservationAmount__c ? this.selectedUnits[key].salesOfferDetails.unitRecord.BuildingSectionName__r.ReservationAmount__c : this.selectedUnits[key].salesOfferDetails.unitRecord.Project__r.ReservationAmount__c;
                    if(upperBound < this.selectedUnits[key].reservationAmount || this.selectedUnits[key].reservationAmount < lowerBound){
                        const evt = new ShowToastEvent({
                            title: 'Invalid Custom Amount',
                            message: 'Reservation amount should be greater than '+lowerBound+' for '+this.selectedUnits[key].unitName+' before submitting ',
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                        this.isLoading=false;
                        return false;
                    }
                }
            }
        }
        return true;
        
    }

    handleChange(event) {
        this[event.target.name] = event.target.value;
    }

    doneTypingInterval = 0;

    handleKeyUp(event) {
        clearTimeout(this.typingTimer);
        let value = event.target.value;
        let name = event.target.name;

        this.typingTimer = setTimeout(() => {
                this[name] = value;
            }, this.doneTypingInterval);
        }

    @track discountAmountField;
    @track rebateAmountField;
    @track sCWaiverAmountField;
    @track pMFeeAmountField;
    @track homeMaintenanceAmountField;
    @track aDMFeeAmountField;
    @track intCommissionAmountField;
    @track brokerCommissionField;
    @track additionalDiscountAmountField;
    @track subsidyAmountField;
    @track netOfferValueField;
    @track netImpactField;
        
    caltculateValue(event){
        //This will work only for selected tab
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        //Calculate the Membership for selcted tab
        if (event.target.name == 'membershipTypeField'){
            pd.membershipTypeField=event.target.value;
            this.membershipValues.forEach(element => {
                if (element.value == event.target.value) {
                    pd.membershipAmountField=element.amount;
                }
            });
        }
        //Calculate the Voucher for selcted tab
        else if (event.target.name == 'voucherNameField'){
            pd.voucherNameField=event.target.value;
            this.voucherValues.forEach(element => {
                if (element.value == event.target.value) {
                    pd.voucherAmountField=element.amount;
                }
            });
        }
        //Calculate other values
        // ======= START: Added by Nikhil (LAS-59) =======
        else if(event.target.name == 'applyPercentageAmount'){
            this.applyPercentageAmount = event.target.value;
            pd.discountValueType = event.target.value;
        }
        // ======= END: Added by Nikhil (LAS-59) =======
        else {
            let value = event.target.value;
            let name = event.target.name;
            //Absolute value
            if(value < 0){
                value = value * -1;
            }
            let calculatedValue = Number(pd.salesOfferDetails.unitRecord.SellingPrice__c) * Number(value) / 100; 
            let calculatedValueWithDiscount = Number(pd.salesOfferDetails.unitRecord.SellingPrice__c - (pd.discountAmountField ? pd.discountAmountField : 0)) * Number(value) / 100; 
            
            if ( name && value < 100) {

                if (name == 'discountPercentageField'){
                    pd.discountPercentageField=value;
                    pd.discountAmountField = calculatedValue;
                    //calculate based on net selling price
                    calculatedValueWithDiscount = Number(pd.salesOfferDetails.unitRecord.SellingPrice__c - (pd.discountAmountField ? pd.discountAmountField : 0)) ; 
                    if(pd.intCommissionPercentageField){pd.intCommissionAmountField = calculatedValueWithDiscount *  Number(pd.intCommissionPercentageField) / 100; }
                    if(pd.brokerCommissionPercentageField){pd.brokerCommissionField= calculatedValueWithDiscount *  Number(pd.brokerCommissionPercentageField) / 100;}

                }else if (name == 'rebatePercentageField'){
                    pd.rebatePercentageField=value;
                    pd.rebateAmountField = calculatedValue;
                }else if (name == 'sCWaiverYearsField'){
                    if (value < 11) {
                        pd.sCWaiverYearsField=value;
                        if (pd.salesOfferDetails.unitRecord.MeasuredArea__c !== null && pd.salesOfferDetails.unitRecord.MeasuredArea__c !== '' && pd.salesOfferDetails.unitRecord.MeasuredArea__c !== undefined) {
                            pd.sCWaiverAmountField = ((pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c && pd.sCWaiverYearsField) ? Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c)* Number(pd.sCWaiverYearsField) : 0)* pd.salesOfferDetails.unitRecord.MeasuredArea__c; //await calculateMultiply({ firstValue : Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c), secondValue: Number(pd.sCWaiverYearsField)}) * pd.salesOfferDetails.unitRecord.MeasuredArea__c;
                        }else{
                            pd.sCWaiverAmountField =  ((pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c && pd.sCWaiverYearsField)? Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c) * Number(pd.sCWaiverYearsField) : 0)* pd.salesOfferDetails.unitRecord.SaleableArea__c; // await calculateMultiply({ firstValue : Number(pd.salesOfferDetails.unitRecord.AnticipatedServiceCharges__c), secondValue: Number(pd.sCWaiverYearsField)}) * pd.salesOfferDetails.unitRecord.SaleableArea__c;
                        }            
                    }
                }else if (name == 'pMFeeYearsField'){
                    if (value < 11) {
                        pd.pMFeeYearsField=value;
                        pd.pMFeeAmountField =  (pd.salesOfferDetails.unitRecord && pd.salesOfferDetails.unitRecord.BuildingSectionName__c && pd.salesOfferDetails.unitRecord.BuildingSectionName__r.PropertyManagementFee__c  && pd.salesOfferDetails.unitRecord.MarketLeaseRent__c && pd.pMFeeYearsField)? ( (Number(pd.salesOfferDetails.unitRecord.BuildingSectionName__r.PropertyManagementFee__c)/100) * Number(pd.salesOfferDetails.unitRecord.MarketLeaseRent__c) * Number(pd.pMFeeYearsField) ):0; //await calculateMultiply({ firstValue : Number(pd.pMFee), secondValue: Number(pd.pMFeeYearsField)}); 
                    }
                }else if (name == 'homeMaintenanceYearsField'){
                    if (value < 11) {
                        pd.homeMaintenanceYearsField=value;
                        pd.homeMaintenanceAmountField = (pd.salesOfferDetails.unitRecord.BuildingSectionName__r.HomeMaintenanceFee__c && pd.homeMaintenanceYearsField)?Number(pd.salesOfferDetails.unitRecord.BuildingSectionName__r.HomeMaintenanceFee__c) * Number(pd.homeMaintenanceYearsField) : 0; //await calculateMultiply({ firstValue : Number(pd.homeMaintenanceFee), secondValue: Number(pd.homeMaintenanceYearsField)}); 
                    }
                }else if (name == 'aDMFeePercentageField'){
                    if (value < 3) {
                        pd.aDMFeeAmountField = calculatedValue;
                        pd.aDMFeePercentageField=value;
                    }
                }else if (name == 'intCommissionPercentageField'){
                    if (value <= Number(MemoDirectCommission)) {
                        pd.intCommissionAmountField = calculatedValueWithDiscount;
                        pd.intCommissionPercentageField=value;
                    }
                }else if (name == 'brokerCommissionPercentageField'){
                    if (value < Number(MemoIndirectCommission)) {
                        pd.brokerCommissionField = calculatedValueWithDiscount;
                        pd.brokerCommissionPercentageField=value;
                    }
                }else if (name == 'subsidyPercentageField'){
                    pd.subsidyAmountField = (Number(pd.salesOfferDetails.unitRecord.SellingPrice__c) * 80 / 100) * Number(value) / 100;
                    pd.subsidyPercentageField=value;
                }
            
            }

            // ======= START: Added by Nikhil (LAS-59) =======
            if (this.applyPercentageAmount === 'Amount' && name === 'discountAmountField') {
                pd.discountPercentageField=((value / pd.salesOfferDetails.unitRecord.SellingPrice__c) * 100);
                pd.discountAmountField = value;
                console.log('pd Amount>>'+pd);
                pd.CurrencyIsoCode = pd.salesOfferDetails.unitRecord.CurrencyIsoCode;
            }
            if (this.applyPercentageAmount === 'Percentage' && name === 'discountPercentageField') {
                pd.discountPercentageField = value;
                pd.discountAmountField = ((value / 100) *  pd.salesOfferDetails.unitRecord.SellingPrice__c);
                console.log('pd percentage>>'+pd);
                pd.CurrencyIsoCode = pd.salesOfferDetails.unitRecord.CurrencyIsoCode;
            }
            // ======= END: Added by Nikhil (LAS-59) =======
        }
        this.selectedUnits[this.currentUnit] = pd;
        this.netValue();
    }

    // ======= START: Added by Nikhil (LAS-59) =======
    get isPercentageSelected() {
        return this.applyPercentageAmount === 'Percentage';
    }

    get isAmountSelected() {
        return this.applyPercentageAmount === 'Amount';
    }
    // ======= END: Added by Nikhil (LAS-59) =======

    netValue(){
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        var unitSellingPrice =  pd.salesOfferDetails.unitRecord.SellingPrice__c;
        this.amountValues = [];
        
        this.amountValues.push(pd.discountAmountField ?  Number(pd.discountAmountField): 0);
        this.amountValues.push(pd.rebateAmountField ?  Number(pd.rebateAmountField): 0);
        this.amountValues.push(pd.sCWaiverAmountField ?  Number(pd.sCWaiverAmountField): 0);
        this.amountValues.push(pd.pMFeeAmountField ?  Number(pd.pMFeeAmountField): 0);
        this.amountValues.push(pd.homeMaintenanceAmountField ?  Number(pd.homeMaintenanceAmountField): 0);
        this.amountValues.push(pd.aDMFeeAmountField ?  Number(pd.aDMFeeAmountField): 0);
        this.amountValues.push(pd.intCommissionAmountField ?  Number(pd.intCommissionAmountField): 0);
        this.amountValues.push(pd.brokerCommissionField ?  Number(pd.brokerCommissionField): 0);
        this.amountValues.push(pd.subsidyAmountField ?  Number(pd.subsidyAmountField): 0);
        this.amountValues.push(pd.membershipAmountField ?  Number(pd.membershipAmountField): 0);
        this.amountValues.push(pd.voucherAmountField ?  Number(pd.voucherAmountField): 0);
        var netOffer =0;
        for(let i = 0 ; i < this.amountValues.length ; i ++){
            if(this.amountValues[i] && this.amountValues[i]!=undefined && this.amountValues[i]!=null){
                netOffer += this.amountValues[i];
            }
        }
        let netImpact = (Number(netOffer)/unitSellingPrice *100)//await calculateNetImpact({netOfferValue: Number(netOffer), unitSellingPrice: unitSellingPrice});

        if (netImpact > 50) {
            const evt = new ShowToastEvent({
                title: 'Net Impact',
                message: 'Summation for all percentage fields should not be more than 50%',
                variant: 'error',
            });
            this.dispatchEvent(evt);
        }
        pd.netImpactField = netImpact.toFixed(2) + ' %';
        pd.netOfferValueField = netOffer;
        
        this.selectedUnits[this.currentUnit] = pd;
    }

    cloneInstallmentLines(){
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        let newTableData = [];

        for(let i = 0 ; i < pd.salesOfferDetails.applicablePaymentPlansCalculated.length ; i ++){
            if ( pd.salesOfferDetails.applicablePaymentPlansCalculated[i].isSelected == true) {
                for (let j = 0; j < pd.salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails.length; j++) {
                    newTableData.push({Milestone: pd.salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.Description__c ,InstallmentNumber:pd.salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.InstallmentNumber__c , ProposedInstallmentPercentage: pd.salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.InstallmentPercentage__c, ProposedBrokerPercentage : pd.salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.BrokerPayoutPercentage__c , ProposedInstallmentDate: pd.salesOfferDetails.applicablePaymentPlansCalculated[i].installmentDetails[j].installmentRecord.InstallmentDate__c });
                }
                pd.dataInstallmentLineChanges = newTableData;
                this.selectedUnits[this.currentUnit] = pd;
            }
        }
    }

    handleSortData() {       
        this.sortBy = 'InstallmentNumber';       
        this.sortDirection = 'asc';       
        this.sortAccountData(this.sortBy);
    }

    sortAccountData(fieldname) {
        let pd = JSON.parse(JSON.stringify(this.selectedUnits[this.currentUnit]));
        
        let parseData = JSON.parse(JSON.stringify(pd.dataInstallmentLineChanges));
       
        let keyValue = (a) => {
            return a[fieldname];
        };

        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; 
            y = keyValue(y) ? keyValue(y) : '';
           
            return ((x > y) - (y > x));
        });
        
        pd.dataInstallmentLineChanges = parseData;
        this.selectedUnits[this.currentUnit] = pd;
    }
}