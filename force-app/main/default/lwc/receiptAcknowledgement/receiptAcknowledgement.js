import { LightningElement,wire,track,api} from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import RECEIPT_ACKOWLEDGEMENT_OBJECT from '@salesforce/schema/ReceiptAcknowledgement__c';
import getConstant from '@salesforce/apex/Utilities.getConstant';
import PAYMENT_MODE from '@salesforce/schema/ReceiptAcknowledgement__c.PaymentType__c';
import BANK_NAME from '@salesforce/schema/ReceiptAcknowledgement__c.BankName__c';
import CURRENCY from '@salesforce/schema/ReceiptAcknowledgement__c.CurrencyIsoCode';
import getparentRecordDetails from "@salesforce/apex/ReceiptAcknowledgementController.initialiseReceiptAcknowlegment";
import getCurrentUserProfile from "@salesforce/apex/ReceiptAcknowledgementController.getCurrentUserProfileName";
import createReceiptAcknowledgementRecord from "@salesforce/apex/ReceiptAcknowledgementController.createReceiptAcknowledgementRecord";
import createReceiptFromSR from "@salesforce/apex/ReceiptAcknowledgementController.createReceiptFromSR";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';  
import { NavigationMixin } from 'lightning/navigation';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import PaymentModeLabel from '@salesforce/label/c.PaymentModes';
import CryptoErrorMessage from '@salesforce/label/c.CryptoErrorMessage';
import { refreshApex } from '@salesforce/apex';
import getAllActiveProjects from '@salesforce/apex/ProjectService.getAllActiveProjects';
import CorporateAccountNumber from '@salesforce/label/c.CorporateAccountNumber';
import getCorporateAccounts from '@salesforce/apex/ReceiptAcknowledgementController.getCorporateAccounts'; //ASF-3419 - add
import EnableBulkInstallmentAllocation from '@salesforce/label/c.EnableBulkInstallmentAllocation'; //FIN-75: Sai Kumar - Bulk Installment Allocation changes
// FIN-147: Sai Kumar - Defaulting logic for Installment Number = 1 and Payment Type = "Online"

export default class ReceiptAcknowledgement extends NavigationMixin(LightningElement) {

    disableSave = true ;
    disableForCrypto = false; 
    @track isLoading = false;
    @track disableAllocationButton = true;
	@track createCase = false;
    @track paymentModes;
    @track currency;
    @track bankNames;
    @track profileName;
    @track paymentMode = '';
    @track amount = '';
	@track selectedAccount = '';//SSR-269
    @track currencyISO = 'AED';
    @track referenceNumber = '';
    @track customerBankName = '';
    @track customerBankNumber = '';
    @track remarks = '';
    @track mortgageCheque = false;
    @track maturityDate = '';
    @api recordId;
    @track installmentRecord = [];
    @track uploadedFiles = []; 
    @track openModal = false;
    @track salesOrderId = '';
    @track parentRecord = [];
    @track payFrom = '';
    @track relatedObject = '';
    @track accountList = [];
	@track accountvalues = [];//SSR-269
    @track payFromAccountId = '';
    @track payFromAccountName = '';
    @track sendForAllocation = false;
    @track bankNameRequired = false;
    @track receiptAckRecordId = [] ; 
    @track maturityDateRequired = true ;
    @track receiptFromSR = true;
    @track accountName = '';
    @track email = '';
    @track isPropertyTransfer = false;
    @track projectOptions = [];
	//Monika: Rebate Request changes
    @track enableCorpBankOptions = false;
    @track virtualAccountName = ''; //ASF-3401
    @track projectCorpAccountName = ''; 
	@track SRType;
    @track isInwardRemittance = false; //Added by Sai Kumar as part of DFC-4 story
    @track inwardRemittanceId; //Added by Sai Kumar as part of DFC-4 story
    @track isUnidentifiedReceipt = false; //Added by Sai Kumar as part of DFC-4 story
    @track accountOptions = [
        {
            label: 'Corporate',
            value: 'Corporate'
        },
        {
            label: 'Escrow',
            value: 'Escrow'
        }
    ];
    @track corporatebankOptions = []; //ASF-3419 - edited
    @track selectedProject='';
    @track selectedAccountType;

    projectDetails = {};
    accountNumber = '';
    uploadeFileIcon = resourcesPath + "/ALDARResources/svg/UploadedFileIcon.svg";
    deleteFileIcon = resourcesPath + "/ALDARResources/svg/DeleteFileIcon.svg";
    glDate;
    selectedCorporateAccountNumber = ''; //ASF-3419 - add
    //Harsh@Aldar ---- Adding the Manager's cheque boolean to the UI for tracking Manager's Cheque payments across resale opp, now redirects to Related SOOC
    @track isPaymentTypeCheque = false;
    @track managerCheque = false;
    @track isSOOCCreatedFromResaleOpp = false; 
    @track resaleOppId;

    // FIN-75: Sai Kumar - Bulk Installment Allocation changes
    @track isPaymentTypeOnline = false;
    @track bulkInstallments = false;
    @track showBulkSelection = false;
    @track installmentList = [];
    @track otherCharges = [];
    @track hasADMFee = false;
    @track admFeeAmount = 0;
    @track initialInstallmentId = null;
    //FIN-75: Sai Kumar - Bulk Installment Allocation changes
    @track isBulkAllocationEnabled = EnableBulkInstallmentAllocation === 'true'; 
    @track hasItemsToShow = false; // FIN-147: Tracked property calculated from parentRecord

    @track acceptFileTypeList = [];
    // FIN-75: Sai Kumar - Bulk Installment Allocation changes
    get isAmountDisabled() {
        return this.paymentMode === 'Online' && this.bulkInstallments && this.isBulkAllocationEnabled;
    }

    connectedCallback(){
        this.glDate = (new Date()).toISOString();
        console.log(this.maturityDate+'- Installment Record - '+this.recordId);
        this.openModal = true;
        //this.paymentModes = PaymentModeLabel.split(',');
        if(PaymentModeLabel){
            const options = PaymentModeLabel.split(';').map((elem) => {
                const option = {
                    label: elem,
                    value: elem
                };
                return option;
               // this.paymentModes = [ ...this.paymentModes, option ];  
            });
            this.paymentModes = options ;
        }
        console.log(PaymentModeLabel+'**Payment Modes**'+this.paymentModes);

        getConstant({
            messageName: 'FileAcceptedReceiptAcknowledgement'
        }).then(result => {
            var acceptedFile = result.ConstantValue__c;
            if (acceptedFile != undefined && acceptedFile != null && acceptedFile != '') {

                this.acceptFileTypeList = [];
                if (acceptedFile.includes(',')) {
                    this.acceptFileTypeList = acceptedFile.split(',');
                } else {
                    this.acceptFileTypeList.push(acceptedFile);
                }

                for (let i = 0; i < this.acceptFileTypeList.length; i++) {
                    this.acceptFileTypeList[i] = this.acceptFileTypeList[i].trim();
                }
            }
            console.log('error' + this.acceptFileTypeList);
        }).catch(error => {
            // console.log('error' + JSON.stringify(error));
            this.showSpinner = false;
        })

        getCurrentUserProfile()
        .then(result => {
            this.profileName = result ;
        })
        .catch(error => {
            console.log('Error in retriving current user profile name');
        });

        getAllActiveProjects()
        .then(result => {
            console.log('result ',result);
            this.projectOptions.push({label:'--None--', value:''});
            result.forEach(element => {
                this.projectDetails[element.Id] = element;
                this.projectOptions.push({label:element.Name, value:element.Id});
            });
            console.log('this.projectOptions ',this.projectOptions);
            this.projectOptions = JSON.parse(JSON.stringify(this.projectOptions));
            console.log('this.projectOptions ',this.projectOptions);
        })
        .catch(error => {
            console.log('Error in retriving all active project',error);
        });
    }

    get isUnidentified(){
        if(this.parentRecord && this.parentRecord.salesOrderRecord && 
           this.parentRecord.salesOrderRecord.Account__c && this.parentRecord.salesOrderRecord.Account__r.Name)
        {
            //Added by Sai Kumar as part of DFC-4 story
            if(this.parentRecord.salesOrderRecord.Account__r.Name == 'UNIDENTIFIED CUSTOMER' || this.isUnidentifiedReceipt){
                return true;
            }
        }
        return false;
    }

     //ASF-3419 - add
     @wire(getCorporateAccounts)
     wiredCorporateAccounts({ error, data }) {
         if (data) {
             this.corporatebankOptions = data.map(record => ({
                 label: record.Account_Number__c,
                 value: record.Account_Number__c
             }));
         } else if (error) {
             console.error('Error fetching corporate accounts', error);
         }
     }

    //---- To get installment details
    @wire(getparentRecordDetails, { recordId: '$recordId' })
    parentRecords({data,error}){ 
        if (data) {
            console.log('Record Data - ',data); 
            this.parentRecord = data ; 
            let buyerOption = null;//SSR-269
            let customerOption = null;//SSR-269
            //Added by Sai Kumar as part of DFC-4 story
            if(data.isInwardRemittance == true) {
                this.isInwardRemittance = true;
                this.inwardRemittanceId = this.recordId;
                this.paymentMode = 'Wire Transfer';
                this.amount = data.amount;
                this.maturityDate = data.paymentDate;
                this.remarks = data.inwardRemittanceRec.Payment_Details__c;//SSR-269
                this.referenceNumber = data.inwardRemittanceRec.Transaction_Reference__c;
                this.salesOrderId = data.salesOrderId ;
            }

            if(data.SRType == 'Rebate Request') 

                {
                    this.isSRRecord = true;//SSR-269

                    this.amount = this.parentRecord.amount ;

                    this.relatedObject = this.parentRecord.objectName ;

                    this.maturityDate = this.parentRecord.paymentDate ;

                    this.receiptFromSR = false;

                    //SSR-269//this.accountName = this.parentRecord.serviceRequestRecord.HexaBPM__Customer__r.Name;

                    //SSR-269//this.email = this.parentRecord.serviceRequestRecord.HexaBPM__Email__c;

                    this.SRType = this.parentRecord.SRType;
                    //SSR-269
					if (this.parentRecord.serviceRequestRecord.HexaBPM__Customer__r) {					
                    customerOption = { label: this.parentRecord.serviceRequestRecord.HexaBPM__Customer__r.Name, value: this.parentRecord.serviceRequestRecord.HexaBPM__Customer__r.Id };
				    this.accountvalues.push(customerOption);
				    }
				    if (this.parentRecord.serviceRequestRecord.BuyerName__r) {		
                	buyerOption = { label: this.parentRecord.serviceRequestRecord.BuyerName__r.Name, value: this.parentRecord.serviceRequestRecord.BuyerName__r.Id };
				        this.accountvalues.push(buyerOption);			
					}
                    //SSR-269
                }

            else{
            //Harsh@Aldar ---- check if the parent SOOC record was charged from Resale Opportunity
            if(data.salesOrderOtherChargesRec.ChargedFromResaleOpp__c){
                this.isSOOCCreatedFromResaleOpp = true;
                console.log('####this.isSOOCCreatedFromResaleOpp --- > : ',this.isSOOCCreatedFromResaleOpp);
                console.log('####this.parentRecord.resaleOpportunityId ---- > : ',this.parentRecord.resaleOpportunityId);
                this.resaleOppId = this.parentRecord.resaleOpportunityId;
            }
            this.amount = this.parentRecord.amount ;
            this.relatedObject = this.parentRecord.objectName ;
            console.log(this.relatedObject+' - Sales Order Number - '+JSON.stringify(this.parentRecord));
            this.salesOrderId = this.parentRecord.salesOrderId ;
            this.maturityDate = this.parentRecord.paymentDate ;
            if(this.parentRecord.relatedAccounts){
                for(const list of this.parentRecord.relatedAccounts){
                    const option = {
                        label: list.Name,
                        value: list.Id
                    };
                    this.accountList = [ ...this.accountList, option ];  
                }
                this.payFromAccountId = this.parentRecord.salesOrderRecord.Account__c; //ASF-3309
                console.log(JSON.stringify(this.accountList)+' - Account List');
            }
            if (this.relatedObject == 'HexaBPM__Service_Request__c') {
				this.isSRRecord = true;//SSR-269
                this.receiptFromSR = false;
                //SSR-269
				if (this.parentRecord.serviceRequestRecord.HexaBPM__Customer__r) {					
                customerOption = { label: this.parentRecord.serviceRequestRecord.HexaBPM__Customer__r.Name, value: this.parentRecord.serviceRequestRecord.HexaBPM__Customer__r.Id };
				this.accountvalues.push(customerOption);
				}
				if (this.parentRecord.serviceRequestRecord.BuyerName__r) {		
                buyerOption = { label: this.parentRecord.serviceRequestRecord.BuyerName__r.Name, value: this.parentRecord.serviceRequestRecord.BuyerName__r.Id };
				this.accountvalues.push(buyerOption);			
			    }
                //SSR-269
                //SSR-269//this.accountName = this.parentRecord.serviceRequestRecord.BuyerName__c != null ? this.parentRecord.serviceRequestRecord.BuyerName__r.Name : this.parentRecord.serviceRequestRecord.HexaBPM__Customer__r.Name;
                if (this.parentRecord.serviceRequestRecord.RecordType.Name == 'Property Transfer' || this.parentRecord.serviceRequestRecord.RecordType.Name == 'Plot Property Transfer' || this.parentRecord.serviceRequestRecord.RecordType.Name == 'Property Transfer NOC') {
                    this.isPropertyTransfer = true;
                }
                //SSR-269//this.email = this.parentRecord.serviceRequestRecord.BuyerEmail__c != null ? this.parentRecord.serviceRequestRecord.BuyerEmail__c : this.parentRecord.serviceRequestRecord.HexaBPM__Email__c;
            } else {
                this.accountName = this.parentRecord.salesOrderRecord.AccountName__c;
            }
            console.log(this.salesOrderId+' - Sales Order - '+JSON.stringify(this.parentRecord.salesOrderRecord));
            if(this.isUnidentified){
                this.paymentModes = [{
                    label: 'Wire Transfer',
                    value: 'Wire Transfer'
                }] ;
                this.paymentMode = 'Wire Transfer';
                this.amount = '';
            }
            if(!data.allowCrypto){
                this.paymentModes = this.paymentModes.filter(option => option.label !== "Crypto Payment");
            }
            
            // FIN-147: Sai Kumar - Calculate hasItemsToShow based on parentRecord data
            this.calculateHasItemsToShow();
			}
        } else if (error) {
            console.log(error);
        }
    };

    //---- To get receipt acknowledgement records
    @wire(getObjectInfo, { objectApiName: RECEIPT_ACKOWLEDGEMENT_OBJECT })
    receiptObject;

    /*
    //------ To get paymentmode dropdown
    @wire(getPicklistValues,{
            recordTypeId: '$receiptObject.data.defaultRecordTypeId', 
            fieldApiName: PAYMENT_MODE
        })
    paymentModes;
    */

    //------ To get Currency dropdown
    @wire(getPicklistValues,{
        recordTypeId: '$receiptObject.data.defaultRecordTypeId', 
        fieldApiName: CURRENCY
    })
    currency;

    //------ To get Bank Name
    @wire(getPicklistValues,{
        recordTypeId: '$receiptObject.data.defaultRecordTypeId', 
        fieldApiName: BANK_NAME
    })
    bankNames;

    //--- On select of payment mode picklist value
    handleChangePaymentMode(event) {
        this.paymentMode = event.detail.value;
        if(this.paymentMode=="Crypto Payment"){
            this.disableForCrypto = true;
            this.referenceNumber = '';
            this.glDate = '';
            this.maturityDate = '';
            this.customerBankName = '';
            this.customerBankNumber = '';
        }else{
            this.disableForCrypto = false;
        }
        if(this.paymentMode=='Cheque'){
            this.bankNameRequired = true ;
            //this.maturityDateRequired = true ; 
            //Harsh@Aldar, if Cheque, turn the Manager's Cheque ON
            this.isPaymentTypeCheque = true;
        }
        else{
            this.bankNameRequired = false ; 
            //this.maturityDateRequired = false ; 
            //Harsh@Aldar, if Cheque, turn the Manager's Cheque ON
            this.isPaymentTypeCheque = false; 
        }
        //Added by Mahidhar ASF-3704
        if(this.paymentMode=='Online'){
            this.bankNameRequired = true ;
            this.customerBankName = 'Abu Dhabi Commercial Bank';
            // FIN-75: Sai Kumar - Bulk Installment Allocation changes
            this.isPaymentTypeOnline = true;
            
            // FIN-147: Sai Kumar - Defaulting logic for Installment Number = 1 and Payment Type = "Online"
            this.handleOnlinePaymentDefaults();
        }
        else{
            this.bankNameRequired = false ; 
            this.customerBankName='';
            // FIN-75: Sai Kumar - Bulk Installment Allocation changes
            this.isPaymentTypeOnline = false;
            this.bulkInstallments = false;
            this.showBulkSelection = false;
            this.calculateTotalAmount();
        }
        this.validateInputs();
    }
    //SSR-269
	handleChangeAccountName(event) {
        this.selectedAccount = event.detail.value;
		if (this.parentRecord.serviceRequestRecord.HexaBPM__Customer__r) {
		if (this.selectedAccount == this.parentRecord.serviceRequestRecord.HexaBPM__Customer__r.Id){
		if (this.parentRecord.serviceRequestRecord.HexaBPM__Customer__r.IsPersonAccount){	
		this.email = this.parentRecord.serviceRequestRecord.HexaBPM__Customer__r.PersonEmail;
		} else {
			this.email = this.parentRecord.serviceRequestRecord.HexaBPM__Customer__r.Email__c;
		    }		
		  }
		} 
		if (this.parentRecord.serviceRequestRecord.BuyerName__r) {
		if (this.selectedAccount == this.parentRecord.serviceRequestRecord.BuyerName__r.Id){
		if (this.parentRecord.serviceRequestRecord.BuyerName__r.IsPersonAccount){
		this.email = this.parentRecord.serviceRequestRecord.BuyerName__r.PersonEmail;
		} else {
			this.email = this.parentRecord.serviceRequestRecord.BuyerName__r.Email__c;
		    }		
		  }
		}
        console.log('Selected Account: ', this.selectedAccount);
    }
    //SSR-269
    //--- On select of currency iso picklist value
    handleChangeCurrency(event) {
        this.currencyISO = event.detail.value;
    }

    //--- On select of Customer Bank Name value
    handleChangeCustomerBankName(event) {
        this.customerBankName = event.detail.value;
        this.validateInputs();
    }

    handleChange(event){
        // this[event.target.dataset.name] = event.target.value;
        // Harsh@Aldar ----- Added Manager Cheque
        if(event.target.dataset.name == 'managerCheque'){
            this[event.target.dataset.name] = event.target.checked;
        }else{
            this[event.target.dataset.name] = event.target.value;
        }
        this.validateInputs();
    } 

    handleChangeEmail(event) {
        this.email = event.detail.value;
    }

    //Added by Sai Kumar as part of DFC-4 story
    handleUnidentifiedReceiptChange(event) {
        this.isUnidentifiedReceipt = event.target.checked;
        this.parentRecord = {...this.parentRecord, isInwardRemittanceForUnidentified: event.target.checked};
    }

    validateInputs() {
        this.disableSave = [this.paymentMode, this.amount, this.referenceNumber,this.remarks].some(value => !value);
        if(this.paymentMode=='Cheque'){
            this.disableSave = [this.paymentMode, this.amount, this.referenceNumber,this.remarks,this.customerBankName,this.maturityDate].some(value => !value);
        }
        if(this.paymentMode == "Crypto Payment"){
            this.disableSave = [this.paymentMode, this.amount, this.remarks].some(value => !value);
        }
        if(this.paymentMode == "Online"){
            this.disableSave = [this.paymentMode, this.amount, this.remarks,this.customerBankName].some(value => !value);
        }
        this.disableAllocationButton = this.disableSave;
        console.log('Current user profileName -'+ this.profileName);
        if(this.paymentMode=='Wire Transfer' && this.profileName != 'Finance Team'){
            this.disableAllocationButton = true;
        }
        // FIN-75: Sai Kumar - Bulk Installment Allocation changes
        if(this.paymentMode == "Online" && this.bulkInstallments){
            this.disableSave = false;
            this.disableAllocationButton = true;
        }
    }
    
    navigateToObjectRecord() {
        console.log('navigating record-'+this.recordId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'InstallmentLines__c',
                actionName: 'view'
            }
        });
    }

    navigateToSOListView(){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.salesOrderId,
                objectApiName: 'SalesOrder__c',
                relationshipApiName: this.relatedObject,
                actionName: 'view'
            },
        }) .then(url => {
            console.log('url'+url);
            this.redirectionPageUrl = url;
        });
    }
    //Harsh@Aldar --- Manager's Cheque -- Naviagate to SOOC on Resale Opportunity, not Sales Order
    navigateToResaleListView(){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.resaleOppId,
                objectApiName: 'Opportunity',
                relationshipApiName: this.relatedObject,
                actionName: 'view'
            },
        }) .then(url => {
            console.log('url'+url);
            this.redirectionPageUrl = url;
        });
    }

    navigateToSOView(){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.salesOrderId,
                objectApiName: 'SalesOrder__c',
                actionName: 'view'
            },
        }) .then(url => {
            console.log('url'+url);
            this.redirectionPageUrl = url;
        });
       
    }

    onFileUpload(event) {
        //---- Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        console.log(event.target.files[0].name+' No. of files uploaded : ' + uploadedFiles.length);
        console.log('uploadedFiles '+JSON.stringify(uploadedFiles));

        function getBase64(file) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.readAsDataURL(file);
                reader.onload = () => resolve(reader.result);
                reader.onerror = error => reject(error);
            });
        }
        
        Array.from(event.target.files).forEach(file => {
            let filePieces = file.name.split('.');
            let fileType = filePieces[filePieces.length - 1].trim();
            
            if (this.acceptFileTypeList.includes(fileType)) {
                var base64;
                getBase64(file).then(
                    data => {
                        base64 = data.split(',')[1];
                    }
                );
                var reader = new FileReader();
                if (event.target.dataset.id === 'paymentFiles') {
                    reader.onload = () => {
                        let result = this.uploadedFiles.filter(obj => {

                            return obj.Title === file.name;
                        });
                        this.uploadedFiles.push({
                            'Title': result?.length > 0 ? file.name + `(${this.uploadedFiles.length})` : file.name,
                            'FileContent': base64,
                        });
                    }
                    reader.readAsDataURL(file);
                } else {
                    console.log('else');
                }
            }
        });

    }

    get acceptedFormats() {
        var acceptFormatList = [];
        for (let i = 0; i < this.acceptFileTypeList.length; i++) {
            acceptFormatList[i] = '.' + this.acceptFileTypeList[i];
        }

        return acceptFormatList;
    }

    removeFile(event) {
        let listName = event.currentTarget.dataset.listname;
        let fileName = event.currentTarget.dataset.id;

        this.uploadedFiles = this.uploadedFiles?.filter(function( obj ) {
            return obj.Title != fileName;
        });
        this.uploadedFiles=[...this.uploadedFiles];

    }   

    handleSaveAllocation () {
        this.sendForAllocation = true;
        this.handleSave();
    }

    handleSave() {
        this.isLoading = true;
        this.disableSave = true ;
        this.disableAllocationButton = true;
        if (this.relatedObject != 'HexaBPM__Service_Request__c') {
                
               
               // FIN-75: Sai Kumar - Bulk Installment Allocation changes
                if (this.bulkInstallments) {
                    const selectedIds = [];
                    if (this.installmentList && Array.isArray(this.installmentList)) {
                        for (const installment of this.installmentList) {
                            if (installment.selected) {
                                selectedIds.push(installment.Id);
                            }
                        }
                    }

                    this.parentRecord = {
                        ...this.parentRecord,
                        selectedInstallmentIds: selectedIds
                    };
                }
                if(this.bulkInstallments){
                    if (this.otherCharges && Array.isArray(this.otherCharges)) {
                        const selectedChargeIds = [];
                        for (const charge of this.otherCharges) {
                            if (charge.selected) {
                                selectedChargeIds.push(charge.Id);
                            }
                        }
                        this.parentRecord = {
                            ...this.parentRecord,
                            selectedChargeIds: selectedChargeIds
                        };
                    }
                }
            console.log('Sales Order - '+this.salesOrderId+'- Account - '+this.parentRecord.salesOrderRecord.Account__c);
            console.log('paymentMode - '+this.paymentMode+' amount - '+this.amount);
            console.log('referenceNumber - '+this.referenceNumber+'- remarks - '+this.remarks);
            console.log('customerBankName - '+this.customerBankName+'- customerBankNumber - '+this.customerBankNumber);
            console.log(this.parentRecord.salesOrderRecord.Opportunity__c+'File Uploaded - '+this.uploadedFiles);
            let receiptAcknowledgementRec = { 'sobjectType': 'ReceiptAcknowledgement__c' };
            receiptAcknowledgementRec.PaymentType__c = this.paymentMode;
            receiptAcknowledgementRec.Amount__c = this.amount ;
            receiptAcknowledgementRec.SalesOrder__c = this.salesOrderId ;
            // receiptAcknowledgementRec.Opportunity__c = this.parentRecord.salesOrderRecord.Opportunity__c ;
            // receiptAcknowledgementRec.Account__c = this.parentRecord.salesOrderRecord.Account__c ;
            //Harsh@Aldar -- Segregating the Resale Opp records
            if(this.isSOOCCreatedFromResaleOpp){
                receiptAcknowledgementRec.Opportunity__c = this.parentRecord.resaleOpportunityId ;
                receiptAcknowledgementRec.Account__c = this.parentRecord.salesOrderOtherChargesRec.Account__c ;
                //Add the Manager's cheque flag on the Acknowledgement record
                receiptAcknowledgementRec.ManagersCheque__c = this.managerCheque;
            }else{
                receiptAcknowledgementRec.Opportunity__c = this.parentRecord.salesOrderRecord.Opportunity__c ;
                receiptAcknowledgementRec.Account__c = this.parentRecord.salesOrderRecord.Account__c ;
            }
            receiptAcknowledgementRec.Remarks__c = this.remarks ;
            receiptAcknowledgementRec.BankName__c = this.customerBankName;
            receiptAcknowledgementRec.CustomerBankAccount__c = this.customerBankNumber;
            receiptAcknowledgementRec.ReferenceNumber__c = this.referenceNumber ;
            if(this.paymentMode == 'Wire Transfer') {
                receiptAcknowledgementRec.Customer_Transfer_Reference__c = this.referenceNumber;
            }
            receiptAcknowledgementRec.MortgageCheque__c = this.mortgageCheque ;
            receiptAcknowledgementRec.MaturityDate__c = this.maturityDate ;
            receiptAcknowledgementRec.CurrencyIsoCode = this.currencyISO ;
            receiptAcknowledgementRec.IsCreatedFromLink__c = true;
            receiptAcknowledgementRec.RecievedFromAccount__c = this.payFromAccountId ;
            receiptAcknowledgementRec.Inward_Remittance__c = this.inwardRemittanceId; //Added by Sai Kumar as part of DFC-4 story
            if(this.isUnidentified){
                receiptAcknowledgementRec.UnidentifiedReceiptProject__c = this.selectedProject;
                receiptAcknowledgementRec.UnidentifiedReceiptAccountType__c = this.selectedAccountType;
                receiptAcknowledgementRec.GLDate__c = this.glDate;
                receiptAcknowledgementRec.IsCreatedFromLink__c = false;
                receiptAcknowledgementRec.Virtual_Account_Name__c = this.virtualAccountName; //ASF-3401
                receiptAcknowledgementRec.UnidentifiedCorporateAccount__c = this.projectCorpAccountName != ''?this.projectCorpAccountName:this.selectedCorporateAccountNumber;
                if((this.selectedProject == '' || this.selectedProject == undefined ) && this.selectedAccountType == 'Escrow'){
                    this.dispatchEvent(  
                        new ShowToastEvent({  
                        title: 'Error',  
                        variant: 'error',  
                        message: 'Project name is required for Escrow account.',  
                        }),  
                    ); 
                    this.isLoading = false;
                    this.disableSave = false ;
                    this.disableAllocationButton = false;
                    return;
                }
                if(this.glDate == undefined || this.glDate == ''){
                    this.dispatchEvent(  
                        new ShowToastEvent({  
                        title: 'Error',  
                        variant: 'error',  
                        message: 'GL Date is Required.',  
                        }),  
                    ); 
                    this.isLoading = false;
                    this.disableSave = false ;
                    this.disableAllocationButton = false;
                    return;
                }
                if((this.accountNumber == undefined || this.accountNumber == '') && isUnidentified == false){ // Added by Sai Kumar as part of DFC-4 story
                    this.dispatchEvent(  
                        new ShowToastEvent({  
                        title: 'Error',  
                        variant: 'error',  
                        message: 'Account Number not Present',  
                        }),  
                    ); 
                    this.isLoading = false;
                    this.disableSave = false ;
                    this.disableAllocationButton = false;
                    return;
                }
            }

            //checking Salesorder compliance status for Crypto
            if(this.parentRecord.salesOrderRecord.ComplianceStatus__c !== "Cleared" && this.paymentMode == "Crypto Payment"){
                this.dispatchEvent(  
                    new ShowToastEvent({  
                    title: 'Error',  
                    variant: 'error',  
                    message: CryptoErrorMessage,  
                    }),  
                ); 
                this.isLoading = false;
                this.disableSave = false ;
                this.disableAllocationButton = false;
                return;
            }

            console.log('receiptAcknowledgementRec - '+JSON.stringify(receiptAcknowledgementRec));
            createReceiptAcknowledgementRecord({recieptRecord: receiptAcknowledgementRec,parentRecord: this.recordId,filesToInsert: this.uploadedFiles,wrapperString:JSON.stringify(this.parentRecord), createThirdPartyCase: this.createCase})
            .then(result => {
                //this.receiptAcknowledgementRec = result;
                this.receiptAckRecordId = result ;
                 //Added by Sai Kumar as part of DFC-4 story
                if (this.isUnidentifiedReceipt) {
                    // Refresh the current page instead of navigating
                    this.dispatchEvent(  
                        new ShowToastEvent({  
                        title: 'Success',  
                        variant: 'success',  
                        message: 'Receipt Acknowledgement Created.',  
                        }),  
                    ); 
                    window.location.reload();
                } else if (this.sendForAllocation) {
                    this.navigateToReceiptAllocation(this.receiptAckRecordId.Id);
                    setTimeout(() => {
                        window.location.href=this.redirectionPageUrl;
                    }, 500);
                    this.isLoading = false;
                } else {
                    this.sendForAllocation = false;
                    this.dispatchEvent(  
                        new ShowToastEvent({  
                        title: 'Success',  
                        variant: 'success',  
                        message: 'Receipt Acknowledgement Created.',  
                        }),  
                    ); 
                    //this.navigateToSOView();
                    // this.navigateToSOListView();
                    //Harsh@Aldar --- Manager Cheque -- handling redirection
                    if(this.isSOOCCreatedFromResaleOpp && this.resaleOppId){
                        this.navigateToResaleListView();
                    }else{
                        this.navigateToSOListView();
                    }
                    console.log(result);
                    setTimeout(() => {
                        window.location.href=this.redirectionPageUrl;
                    }, 500);
                    this.isLoading = false;
                }
            })
            .catch(error => {
                this.sendForAllocation = false;
                console.log(error);
                let errorMsg = '';
                if(error.body.message != undefined && error.body.message != null){
                  if(error.body.message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                    errorMsg = error.body.message.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,')[1].split(':')[0]
                   }
                }else {
                    errorMsg = error;
                }
                this.error = error;

                this.dispatchEvent(  
                    new ShowToastEvent({  
                      title: 'Error',  
                      variant: 'error',  
                      message: errorMsg,  
                    }),  
                  ); 
                this.disableSave = false ;
                this.isLoading = false;
                if(this.paymentMode == 'Wire Transfer') {
                    this.disableAllocationButton = true;
                } 
                else {
                    this.disableAllocationButton = false;
                }
            });
        } else {
            this.handleSaveReceipt();
        }
    }

    handleSaveReceipt() {
        let receiptAcknowledgementRec = { 'sobjectType': 'ReceiptAcknowledgement__c' };
        receiptAcknowledgementRec.PaymentType__c = this.paymentMode;
        receiptAcknowledgementRec.Amount__c = this.amount ;
		
        //Monika: Rebate Request Changes
        if(this.SRType!= 'Rebate Request')
            {
            receiptAcknowledgementRec.SalesOrder__c = this.salesOrderId ; 
            }
            else{

			}
        receiptAcknowledgementRec.Opportunity__c = this.parentRecord.salesOrderRecord.Opportunity__c ;
        //receiptAcknowledgementRec.Account__c = this.parentRecord.serviceRequestRecord.BuyerName__c ;
		//Monika: Rebate Request changes
		//SSR-269
        //receiptAcknowledgementRec.Account__c = this.SRType!= 'Rebate Request'?this.parentRecord.serviceRequestRecord.BuyerName__c:this.parentRecord.AccountId ;
		if(this.relatedObject == 'HexaBPM__Service_Request__c'){
		    receiptAcknowledgementRec.Account__c = this.selectedAccount;
		    if(this.email != null && this.email != '') {
            receiptAcknowledgementRec.ReceiptEmail__c = this.email;
        }
		} else{
			receiptAcknowledgementRec.Account__c = this.parentRecord.serviceRequestRecord.BuyerName__c;
		}
        receiptAcknowledgementRec.ServiceRequest__c = this.parentRecord.serviceRequestRecord.Id;
        //if(this.isPropertyTransfer && this.email != null && this.email != '') {
        //    receiptAcknowledgementRec.ReceiptEmail__c = this.email;
        //}
        //SSR-269
        receiptAcknowledgementRec.Remarks__c = this.remarks ;
        receiptAcknowledgementRec.BankName__c = this.customerBankName;
        receiptAcknowledgementRec.CustomerBankAccount__c = this.customerBankNumber;
        receiptAcknowledgementRec.ReferenceNumber__c = this.referenceNumber ;
        if(this.paymentMode == 'Wire Transfer') {
            receiptAcknowledgementRec.Customer_Transfer_Reference__c = this.referenceNumber;
        }
        receiptAcknowledgementRec.MortgageCheque__c = this.mortgageCheque ;
        receiptAcknowledgementRec.ManagersCheque__c = this.managerCheque;
        receiptAcknowledgementRec.MaturityDate__c = this.maturityDate ;
        receiptAcknowledgementRec.CurrencyIsoCode = this.currencyISO ;
        receiptAcknowledgementRec.IsCreatedFromLink__c = false;
        receiptAcknowledgementRec.RecievedFromAccount__c = this.payFromAccountId ;
        console.log('receiptAcknowledgementRec - '+JSON.stringify(receiptAcknowledgementRec));
        console.log('File Uploaded - '+this.uploadedFiles);
        createReceiptFromSR({
            recieptRecord: receiptAcknowledgementRec,
            filesToInsert: this.uploadedFiles
        }).then(result => {
            this.receiptAckRecordId = result ;
            this.sendForAllocation = false;
            this.dispatchEvent(  
                new ShowToastEvent({  
                title: 'Success',  
                variant: 'success',  
                message: 'Receipt Acknowledgement Created.',  
                }),  
            ); 
            this.navigateToServiceRequestView();
            console.log(result);
            setTimeout(() => {
                window.location.href=this.redirectionPageUrl;
            }, 500);
            this.isLoading = false;
        }).catch(error => {
            this.sendForAllocation = false;
            console.log(error);
            this.error = error;
            this.dispatchEvent(  
                new ShowToastEvent({  
                  title: 'Error',  
                  variant: 'error',  
                  message: 'An error occurred, please try again.',  
                }),  
              ); 
            this.disableSave = false ;
            this.isLoading = false;
            if(this.paymentMode == 'Wire Transfer') {
                this.disableAllocationButton = true;
            } else {
                this.disableAllocationButton = false;
            }
        });
    }

    navigateToServiceRequestView() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'HexaBPM__Service_Request__c',
                actionName: 'view'
            },
        }) .then(url => {
            console.log('url'+url);
            this.redirectionPageUrl = url;
        });
    }

    navigateToReceiptAllocation(receiptAllocationId) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Receipt_Allocation',
            },
            state: {
                'c__rId': receiptAllocationId,
                'c__isOpen': true
            }
        }) .then(url => {
            console.log('url'+url);
            this.redirectionPageUrl = url;
        });
    }

    closeModal() {
        this.openModal = false;
        //Added by Sai Kumar as part of DFC-4 story
        if (this.isInwardRemittance) {
            // Refresh the current page instead of navigating
            window.location.reload();
        } else if (this.relatedObject == 'HexaBPM__Service_Request__c') {
            this.navigateToServiceRequestView();
            setTimeout(() => {
                window.location.href=this.redirectionPageUrl;
            }, 300);
        } else {
            if(this.isSOOCCreatedFromResaleOpp && this.resaleOppId){
                this.navigateToResaleListView();
            }else{
                this.navigateToSOListView();
            }
        setTimeout(() => {
            window.location.href=this.redirectionPageUrl;
        }, 300);
    }
    }

    handleProjectChange(event){
        this.selectedProject = event.detail.value;
        if(this.isUnidentified){
            this.handleGetAccountNumber();
        }
        
    }
	
    handlevirtualAccountNameChange(event) { //ASF-3401
        this.virtualAccountName = event.detail.value;
    }

	handleCreateCaseChange(event) {
        this.createCase = event.target.checked;
    }
	
    handleAccountOptionChange(event){
        this.selectedBankName = '';
        if(event.target.name=='accountoptionname'){
         this.selectedAccountType = event.detail.value;
        }else if(event.target.name=='corporateBankname'){
            this.selectedCorporateAccountNumber = event.detail.value; //ASF-3419 - replaced 
        }
        if(this.isUnidentified){
            this.handleGetAccountNumber();
        }
    }

    handleGetAccountNumber(){
        console.log('handle account number');
        this.enableCorpBankOptions =false;
        if(this.selectedProject != "" && this.selectedAccountType != undefined){
            if(this.projectDetails[this.selectedProject] != undefined){
                if(this.selectedAccountType == 'Corporate'){
                    this.accountNumber = this.projectDetails[this.selectedProject].AccountNumberCorporate__c;
                    this.projectCorpAccountName = this.accountNumber;
                }else if(this.selectedAccountType == 'Escrow'){
                    this.accountNumber = this.projectDetails[this.selectedProject].AccountNumberEscrow__c
                }
            }
        }else if((this.selectedProject == "" || this.selectedProject != undefined) && this.selectedAccountType != undefined){
            if(this.selectedAccountType == 'Corporate'){
                    this.accountNumber = this.selectedCorporateAccountNumber; //ASF-3419 - add
                    this.enableCorpBankOptions = true;
            }else {
                this.accountNumber = '';
            }
        }else{
            this.accountNumber = ''; 
        }
    }

    // FIN-75: Sai Kumar - Bulk Installment Allocation changes
    handleBulkInstallmentsChange(event) {
        this.bulkInstallments = event.target.checked;
        this.showBulkSelection = this.bulkInstallments;
        if (this.bulkInstallments) {
            this.loadInstallmentList();
            this.loadOtherCharges();
            // Disable Save Receipt & Allocation button and enable Save Receipt button when bulk selection is enabled
            
            this.disableAllocationButton = true;
            this.disableSave = false;
        } else {
            this.installmentList = [];
            this.otherCharges = [];
            this.calculateTotalAmount();
            // Reset button states when bulk selection is disabled
            this.disableAllocationButton = false;
            this.disableSave = true;
        }
    }

    // FIN-75: Sai Kumar - Bulk Installment Allocation changes
    loadInstallmentList() {
        if (this.parentRecord && this.parentRecord.otherInstallments) {
            this.installmentList = this.parentRecord.otherInstallments.map(installment => ({
                ...installment,
                selected: false
            }));
            this.hasADMFee = this.parentRecord.hasADMFee;
            this.admFeeAmount = this.parentRecord.admFeeAmount;
        } else {
            this.installmentList = [];
            this.hasADMFee = false;
            this.admFeeAmount = 0;
        }
    }

    // FIN-75: Sai Kumar - Bulk Installment Allocation changes
    loadOtherCharges() {
        if (this.parentRecord && this.parentRecord.otherCharges) {
            this.otherCharges = this.parentRecord.otherCharges.map(charge => ({
                ...charge,
                selected: false
            }));
        } else {
            this.otherCharges = [];
        }
    }

    // FIN-75: Sai Kumar - Bulk Installment Allocation changes
    handleInstallmentSelection(event) {
        const installmentId = event.target.dataset.id;
        const installment = this.installmentList.find(inst => inst.Id === installmentId);
        if (installment && !installment.isInitial) {
            installment.selected = event.target.checked;
            this.calculateTotalAmount();
        }
    }


    // FIN-75: Sai Kumar - Bulk Installment Allocation changes
    calculateTotalAmount() {
        let total = 0;
        const baseAmount = this.parentRecord.amount != null ? this.parentRecord.amount : 0;
        console.log('this.parentRecord.amount-----' + baseAmount);
        if (this.bulkInstallments) {
            // Sum selected installments
            total = baseAmount;
            this.installmentList.forEach(installment => {
                if (installment.selected) {
                    total += installment.PendingAmount__c;
                }
            });

            // Add selected charges
            this.otherCharges.forEach(charge => {
                if (charge.selected) {
                    total += charge.PendingAmount__c;
                }
            });
        } else {
            // Use single installment amount
            total = baseAmount;
        }
        this.amount = total;
    }

    // FIN-75: Sai Kumar - Bulk Installment Allocation changes
    handleChargeSelection(event) {
        const chargeId = event.target.dataset.id;
        const charge = this.otherCharges.find(chg => chg.Id === chargeId);
        if (charge) {
            charge.selected = event.target.checked;
            this.calculateTotalAmount();
        }
    }

    // FIN-147: Sai Kumar - Check if current installment is the first installment (Installment Number = 1)
    get isFirstInstallment() {
        return this.parentRecord && 
               this.parentRecord.installmentRec && 
               this.parentRecord.installmentRec.InstallmentNumber__c === 1;
    }

    // FIN-147: Sai Kumar - Calculate hasItemsToShow based on parentRecord data
    calculateHasItemsToShow() {
        this.hasItemsToShow = (this.parentRecord && 
                              this.parentRecord.otherInstallments && 
                              this.parentRecord.otherInstallments.length > 0) ||
                             (this.parentRecord && 
                              this.parentRecord.otherCharges && 
                              this.parentRecord.otherCharges.length > 0);
    }

    // FIN-147: Sai Kumar - Handle defaulting logic for Online payment type
    handleOnlinePaymentDefaults() {
        // Only apply defaults for first installment (Installment Number = 1)
        if(this.isBulkAllocationEnabled){
            this.loadInstallmentList();
            this.loadOtherCharges();
        }
        if (this.isFirstInstallment && this.hasItemsToShow && this.isBulkAllocationEnabled) {
            // Default the "Send Unified Payment Link" checkbox to checked
            this.bulkInstallments = true;
            this.showBulkSelection = true;
            
            // Default applicable charge checkboxes (e.g., ADM Fee) to checked
            if (this.otherCharges && this.otherCharges.length > 0) {
                this.otherCharges.forEach(charge => {
                    // Check if it's an applicable charge type (ADM Fee, DLD, RAK Municipality Fee)
                    if (charge.TypeOfCharge__c === 'ADM Fee' || 
                        charge.TypeOfCharge__c === 'DLD' || 
                        charge.TypeOfCharge__c === 'RAK Municipality Fee') {
                        charge.selected = true;
                    }
                });
            }
            
            // Recalculate total amount with selected items
            this.calculateTotalAmount();
            
            // Update button states
            this.disableAllocationButton = true;
            this.disableSave = false;
        }
    }
    

}