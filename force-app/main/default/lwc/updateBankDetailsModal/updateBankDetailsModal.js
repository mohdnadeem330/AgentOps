import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import enableDisableOtp from '@salesforce/label/c.EnableDisableOTP';
import getCountyPicklistValues from '@salesforce/apex/UserProfileController.getPicklistValuesGeneric';
// import getCurrecyPicklistValues from '@salesforce/apex/UserProfileController.getPicklistValuesGeneric';
import getValidateIBAN from '@salesforce/apex/IBANValidation.getValidateIbanWithAura';
import getPrimaryOwnerOrAdminDetails from '@salesforce/apex/UserProfileController.getPrimaryOwnerOrAdminDetails';
import sentSMSOTP from '@salesforce/apex/UserProfileController.sentOTP';
import sentEmailOTP from '@salesforce/apex/UserProfileController.sentOTP'; 
import resendOTP from '@salesforce/apex/UserProfileController.sentOTP';
import getOtpDetails from '@salesforce/apex/UserProfileController.getOtpDetails'; 
import bankDetailsCRSubmit from '@salesforce/apex/UserProfileController.bankDetailsCRSubmit'; 
import uploadFile from '@salesforce/apex/UserProfileController.uploadFile'; 
import fetchOTPExpiryTime from '@salesforce/apex/CommunityAuthController.getBrokerOTPTimer';
import otpReceiverType from '@salesforce/label/c.BPM_BankOTPOwnership';

export default class UpdateBankDetailsModal extends LightningElement {
    @api userRecord; 
    @track muskEmailId; @track muskMobileNumber; @track confirmAccountNumber;
    @track showSpinner = false; @track errorDetails; @track errorDialog; @track files = []; @track countyNames = [];
    @track selectedCountry; @track currencyCodes = []; @track selectedCurrency; @track isIBANRequired = false; 
    @track isRequiredIBAN = false; @track ibanNumberResponse = false; @track bankName; @track bankBranch; 
    @track accountNumber; @track IBANNumber; @track confirmIBANNumber; @track swiftCode; @track otpSection = false;
    @track isSMSVerified = false; @track isEmailVerified = false; @track smsOtpValue; @track emailOtpValue; 
    @track primaryOwnerAdminRecord = {}; @track showTimer = false; @track countDown; @track timerTextValue;
    @track isOtpValidatedWithInCount = true; @track isNeedToClearSetInterval = false; @track finalSubmittionError = false;
    @track ibnNumberValidator = 'valid'; @track isUserDomestic = true;
    @track skippedSMSOTP = false; @track skippedEmilOTP = false; 
    @track beneficiaryName = ''; requiredBeneficiaryName = false; disabledBeneficiaryName = false;
    @track isRequiredAccountNumber = false;
    isChanged = false; isValidAcc = true; otpReceiverType = otpReceiverType;

    uploadeFileIcon = resourcesPath + "/ALDARResources/svg/UploadedFileIcon.svg";
    deleteFileIcon = resourcesPath + "/ALDARResources/svg/DeleteFileIcon.svg";
    bigEditIcon = resourcesPath + "/ALDARResources/svg/BigEditIcon.svg";
    testUserPhoto = resourcesPath + "/ALDARResources/png/Avatar.png";

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg'];
    }

    get isDomesticSMSTrue(){
        return (enableDisableOtp.split(',')[0]).toLowerCase() == 'enabledomesticsms';
    }

    get isINTLSMSTrue(){
        return (enableDisableOtp.split(',')[1]).toLowerCase() == 'enableintlsms';
    }

    get isDomesticEmailTrue(){
        return (enableDisableOtp.split(',')[2]).toLowerCase() == 'enabledomesticemail'; 
    }

    get isINTLEmailTrue(){
        return (enableDisableOtp.split(',')[3]).toLowerCase() == 'enableintlemail'; 
    }

    get requiredAttachment(){
        return this.files.length == 0;
    }

    get disbledInputs(){
        return !this.primaryOwnerAdminRecord || this.primaryOwnerAdminRecord == undefined || this.primaryOwnerAdminRecord == null;
    }

    @wire(getCountyPicklistValues,{sObjectName : 'Account',  fieldName : 'BankCountry__c'})
    wiredCountyNamesPicklist({ error, data }) {
        if (data) {
            this.countyNames = data; 
        } else if (error) {
            this.countyNames = [];
        }
    }

    @wire(getValidateIBAN, { ibanNumber: '$confirmIBANNumber' })
    ibanNumberResponse;

    @wire(fetchOTPExpiryTime)
    wiredData({ error, data }) {
        if (data) {
            this.countDown = data.Timer__c * 60;
        } else if (error) {
            console.error('Error:', error);
        }
    }

    @wire(getPrimaryOwnerOrAdminDetails,{accountId : '$userRecord.AccountId'})
    getPrimaryOwnerAdminRecord({error, data}){
        if(data){
            if(data !== undefined && data !== null && data.length > 0){
                this.primaryOwnerAdminRecord = data[0];
                let mobile = this.primaryOwnerAdminRecord.MobilePhone__c;
                let emailSplit = this.primaryOwnerAdminRecord.Email.split('@');
                let showFirstChar = emailSplit[0].length > 3 ? 3 : (emailSplit[0].length - 1);
                
                this.muskMobileNumber = mobile.substr(mobile.length - 4);
                this.muskEmailId = emailSplit[0].substring(0, showFirstChar)+'*****'+'@'+emailSplit[1];

                if(this.primaryOwnerAdminRecord.MobileCountryCode__c === '971' || this.primaryOwnerAdminRecord.MobileCountryCode__c === '97'){
                    this.isUserDomestic = true;
                }else{
                    this.isUserDomestic = false;
                }
            }else{
                this.primaryOwnerAdminRecord = undefined;
            }
        }else if(error){
            this.primaryOwnerAdminRecord = undefined;
        }
    }

    connectedCallback(){
        this.showSpinner = true;
        if(this.userRecord){ 
            this.bankName = this.userRecord.Account.BankName__c;
            this.bankBranch = this.userRecord.Account.BranchAddress__c;
            this.accountNumber = this.userRecord.Account.BankAccountNumber__c;
            this.confirmAccountNumber = this.userRecord.Account.BankAccountNumber__c;
            this.IBANNumber = this.userRecord.Account.IBANNumber__c;
            this.confirmIBANNumber = this.userRecord.Account.IBANNumber__c;
            this.swiftCode = this.userRecord.Account.SwiftCode__c
            this.selectedCountry = this.userRecord.Account.BankCountry__c;
            this.selectedCurrency = this.userRecord.Account.CurrencyIsoCode;
            this.beneficiaryName = this.userRecord.Account.BeneficiaryName__c != null ? this.userRecord.Account.BeneficiaryName__c : this.userRecord.Account.Name;
            this.requiredBeneficiaryName = this.userRecord.Account.BillingCountry != 'United Arab Emirates' ? true : false;
            this.disabledBeneficiaryName = !this.requiredBeneficiaryName;

            if(this.selectedCountry === 'United Arab Emirates'){
                this.isRequiredIBAN = true;
                this.isRequiredAccountNumber = true;
            }
            this.showSpinner = false;
        }
    }

    handleChange(event){
        this.isChanged = true;
        let targetName = event.target.dataset.id;
        let value = event.target.value;

        if(targetName === 'bankName'){
            this.bankName = value;
        }else if(targetName === 'bankBranch'){
            this.bankBranch = value;
        }else if (targetName === 'beneficiaryName'){
            this.beneficiaryName = value;
        }
        else if(targetName === 'accountNumber'){
            // Added By Moh Sarfaraj for BPM-336
            this.accountNumber = value.replaceAll(/[^a-zA-Z0-9]/ig, '');

            if(this.selectedCountry !== 'United Arab Emirates'){
                this.isRequiredAccountNumber = (value && value.length) > 0 ?  true : false;
            }else{
                this.isRequiredAccountNumber = true;
            }

            let target = this.template.querySelector('[data-id="confirmAccountNumber"]');
            target.setCustomValidity("");
            if(this.confirmAccountNumber){
                if(value !== this.confirmAccountNumber){
                    target.setCustomValidity("Account Number is not Matched");
                }else{
                    // Added By Moh Sarfaraj for BPM-336
                    if(this.isRequiredAccountNumber && this.confirmIBANNumber){
                        this.isValidAcc = this.confirmIBANNumber.toLowerCase().includes(this.accountNumber.toLowerCase());
                        if(this.isValidAcc){
                            target.setCustomValidity("");
                        }else{
                            target.setCustomValidity("Please Enter a Valid Account Number");
                        }
                        target.reportValidity();
                        return;
                    }else{
                        target.setCustomValidity("");
                    }
                }
            }
            target.reportValidity();
        }if(targetName ==='confirmAccountNumber'){
            // Added By Moh Sarfaraj for BPM-336
            this.confirmAccountNumber = value.replaceAll(/[^a-zA-Z0-9]/ig, '');

            if(this.selectedCountry !== 'United Arab Emirates'){
                this.isRequiredAccountNumber = (value && value.length > 0) ?  true : false;
            }else{
                this.isRequiredAccountNumber = true;
            }

            let target = this.template.querySelector('[data-id="confirmAccountNumber"]');
            target.setCustomValidity("");
            if(this.accountNumber){
                if(value !==  this.accountNumber){
                    target.setCustomValidity("Account Number is not Matched");
                }else{
                    // Added By Moh Sarfaraj for BPM-336
                    if(this.isRequiredAccountNumber && this.confirmIBANNumber){
                        this.isValidAcc = this.confirmIBANNumber.toLowerCase().includes(this.confirmAccountNumber.toLowerCase());
                        if(this.isValidAcc){
                            target.setCustomValidity("");
                        }else{
                            target.setCustomValidity("Please Enter a Valid Account Number");
                        }
                        target.reportValidity();
                        return;
                    }else{
                        target.setCustomValidity("");
                    }
                }
            }
            target.reportValidity();
        }else if(targetName === 'IBAN'){
            // Added By Moh Sarfaraj for BPM-336
            this.IBANNumber = undefined;
            this.IBANNumber = value.replaceAll(/[^a-zA-Z0-9]/ig, '');
            this.ibnNumberValidator = 'valid';

            if(this.selectedCountry !== 'United Arab Emirates'){
                this.isRequiredIBAN = (value && value.length) > 0 ?  true : false;
            }else{
                this.isRequiredIBAN = true;
            }
            
            let syncTarget = this.template.querySelector('[data-id="confirmIBAN"]');
            syncTarget.setCustomValidity("");  

            let lowerCase = value.toLowerCase();
            if(lowerCase !== this.confirmIBANNumber.toLowerCase()){
                this.ibnNumberValidator = 'not matched';
                syncTarget.setCustomValidity("Enter IBAN Number is not matched")  
                syncTarget.reportValidity(); 
                return;
            }
            syncTarget.reportValidity(); 

            if(this.confirmIBANNumber && this.confirmIBANNumber.length > 0){
                this.showSpinner = true;
                setTimeout(() => {
                    let target = this.template.querySelector('[data-id="confirmIBAN"]');
                    if (!this.ibanNumberResponse.data) {
                        this.ibnNumberValidator = 'not valid';
                        this.showSpinner = false;
                        target.setCustomValidity("Enter Valid IBAN Number.")
                    } else {
                        // Added By Moh Sarfaraj for BPM-336
                        if(this.selectedCountry == 'United Arab Emirates' && this.confirmAccountNumber && this.confirmAccountNumber.length > 0){
                            let targetConfirmAccount = this.template.querySelector('[data-id="confirmAccountNumber"]');
                            this.isValidAcc = this.confirmIBANNumber.toLowerCase().includes(this.confirmAccountNumber.toLowerCase());
                            if(this.isValidAcc){
                                targetConfirmAccount.setCustomValidity("");
                            }else{
                                targetConfirmAccount.setCustomValidity("Please Enter a Valid Account Number");
                            }
                            this.showSpinner = false;
                            targetConfirmAccount.reportValidity();
                        }else{
                            this.showSpinner = false;
                            target.setCustomValidity("");
                        }
                    }
                    target.reportValidity();
                }, 3000);
            }
        }else if(targetName === 'confirmIBAN'){
            let syncTarget = this.template.querySelector('[data-id="confirmIBAN"]');
            this.confirmIBANNumber = undefined;
            this.confirmIBANNumber = value.replaceAll(/[^a-zA-Z0-9]/ig, '');
            this.ibnNumberValidator = 'valid';
            syncTarget.setCustomValidity("");  
            
            let lowerCase = this.confirmIBANNumber.toLowerCase();
            if(lowerCase !== this.IBANNumber.toLowerCase()){
                syncTarget.setCustomValidity("Enter IBAN Number is not matched") 
                this.ibnNumberValidator = 'not matched'; 
                syncTarget.reportValidity(); 
                return;
            }
            syncTarget.reportValidity();
                
            if(this.confirmIBANNumber.length != 0){
                this.showSpinner = true;
                setTimeout(() => {
                    let target = this.template.querySelector('[data-id="confirmIBAN"]');

                    if (!this.ibanNumberResponse.data) {
                        this.showSpinner = false;
                        this.isValidIBANNumber = false;
                        this.ibnNumberValidator = 'not valid';
                        target.setCustomValidity("Enter Valid IBAN Number.");
                    } else {
                        // Added By Moh Sarfaraj for BPM-336
                        if(this.selectedCountry == 'United Arab Emirates' && this.confirmAccountNumber && this.confirmAccountNumber.length > 0){
                            let targetConfirmAccount = this.template.querySelector('[data-id="confirmAccountNumber"]');
                            this.isValidAcc = this.confirmIBANNumber.toLowerCase().includes(this.confirmAccountNumber.toLowerCase());
                            if(this.isValidAcc){
                                targetConfirmAccount.setCustomValidity("");
                            }else{
                                targetConfirmAccount.setCustomValidity("Please Enter a Valid Account Number");
                            }
                            this.showSpinner = false;
                            targetConfirmAccount.reportValidity();
                        }else{
                            this.showSpinner = false;
                            target.setCustomValidity("");
                        }
                    }
                    target.reportValidity();
                }, 3000);
            }
        }else if(targetName === 'swiftCode'){
            this.swiftCode = value;
        }else if(targetName === 'currency'){
            this.selectedCurrency = value;
        }else if(targetName === 'country'){
            this.selectedCountry = value;
            if(value === 'United Arab Emirates'){
                this.isRequiredIBAN = true;
                this.isRequiredAccountNumber = true;
            }else{
                this.isRequiredIBAN = false;
                this.isRequiredAccountNumber = false;
            }
        }
    }

    async upload(fileData, recordId) {
        await Array.from(fileData).forEach(file => {
            const { base64, filename, type } = file;
            if (base64 != null) {
                this.showSpinner = true;
                
                uploadFile({ base64, filename, type, recordId }).then(result => {
                    file = null;
                    this.showSpinner = false;
                }).catch(error => {
                    this.showSpinner = false;
                });
            }
        });
    }

    async openfileUpload(event) {
        let type = 'Bank Copy';

        function getBase64(file) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.readAsDataURL(file);
                reader.onload = () => resolve(reader.result);
                reader.onerror = error => reject(error);
            });
        }

        await Array.from(event.target.files).forEach(file => {
            var base64;
            getBase64(file).then(
                data => {
                    base64 = data.split(',')[1];
                }
            );
            let fileSize = file.size;
            var reader = new FileReader();

            reader.onload = () => {
                if(file.size > 2500000){
                    this.showToast('Error','File size is More Than 2 MB.', 'error');
                    this.errorDetails.push('File size is More Than 2 MB.');
                    this.files = [];
                    return;
                }else if ((file.size + new Blob([JSON.stringify(this.files)]).size) > 2500000){ 
                    this.showToast('Error','Total File size is More Than 2 MB.', 'error');
                    this.errorDetails.push('Total File size is More Than 2 MB.');
                    return;
                }
                let result = this.files.filter(obj => {
                    if(obj.filename === file.name){
                        this.showToast('Error','File already exists', 'error');
                        this.errorDetails.push('File already exists');
                        return;
                    }
                });
                this.files.push({
                    'filename': result?.length > 0 ? file.name + `(${this.files.length})` : file.name,
                    'base64': base64,
                    'fileSize': fileSize,
                    'type' : type
                });
            }
            reader.readAsDataURL(file);
        });
    }

    removeFile(event) {
        let fileName = event.currentTarget.dataset.id;

        this.files = this.files.filter(function (obj) {
            return obj.filename != fileName;
        });
        this.files = [...this.files];
    }

    partialSubmit(event){
        let isError = false;
        this.finalSubmittionError = false;
       
        if(!this.primaryOwnerAdminRecord){
            const evt = new ShowToastEvent({
                title: this.otpReceiverType +' Details',
                message: 'Please Update Email Address and Mobile Number of '+ this.otpReceiverType +' of the Agency',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            return;
        }

        if(!this.isChanged){
            const evt = new ShowToastEvent({
                title: 'Information Change',
                message: 'Please change the information to proceed',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            return;
        }
        // Added By Moh Sarfaraj for BPM-336
        if(this.selectedCountry === 'United Arab Emirates' && !this.isValidAcc){
            const evt = new ShowToastEvent({
                title: 'Invalid Account Number',
                message: 'Your Account Number is Invalid',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            return;
        }

        if(this.ibnNumberValidator !== 'valid'){
            const evt = new ShowToastEvent({
                title: 'IBAN Number Validation Failed',
                message: 'Your IBAN Number is '+this.ibnNumberValidator,
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            return;
        }
        if(this.selectedCountry !== 'United Arab Emirates' && (!this.confirmIBANNumber &&  !this.accountNumber)){
            const evt = new ShowToastEvent({
                title: 'Account Details Blank',
                message: 'Please Enter Account Number or IBAN Number',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            return;
        }
        if(this.accountNumber !== this.confirmAccountNumber){
            const evt = new ShowToastEvent({
                title: 'Account Number is not matched',
                message: 'Please Enter Confirm Account Number same as Account Number',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            return;
        }
        this.template.querySelectorAll('lightning-input').forEach(element => {
            element.reportValidity();
            if(element.required && !element.value){
                isError = true;
            }
        });
        this.template.querySelectorAll('lightning-combobox').forEach(element => {
            element.reportValidity();
            if(element.required && !element.value){
                isError = true;
            }
        });
        if(this.files.length == 0){
            isError = true;
        }
        if(isError){
            const evt = new ShowToastEvent({
                title: 'Reqired Fields Missing',
                message: 'Please Populate all the fields before Submitting',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        }
        if(!isError){
            this.showSpinner = true;
            // send SMS OTP 
            if(this.isDomesticSMSTrue || this.isINTLSMSTrue || this.isDomesticEmailTrue || this.isINTLEmailTrue){
                this.otpSection = true;
    
                if((this.isUserDomestic && this.isDomesticSMSTrue) || (!this.isUserDomestic && this.isINTLSMSTrue)){
                    sentSMSOTP({ accountId : this.userRecord.AccountId, type : 'sms'})
                    .then(results=>{
                        // alert(JSON.stringify(results));
                        if(results === 'success'){
                            this.showSpinner = false;
                            this.isNeedToClearSetInterval = false;
                            this.countDownUtlityFunction();

                            this.showToast('Success', 'Your SMS OTP has been Sent Successfully', 'success')
                        }else{
                            this.showSpinner = false;
                            this.showToast('Error', 'An Unexpected Error occured while Sending the SMS', 'error');
                        }
                    }).catch(error=>{
                        this.showSpinner = false;
                        this.showToast('Error', error.body.message, 'error');
                    })
                }else{
                    this.skippedSMSOTP = true;
                    this.isSMSVerified = true;
                    this.isOtpValidatedWithInCount = true;
                    this.validateSMS_OTP();
                }
            }else{
                this.submitBankDetails();
            }
        } 
    }

    handleOTP(event){
        let target = event.target.dataset.id;
        let value = event.target.value;
    
        if(target === 'smsOTP'){
            this.smsOtpValue = value;
        }else if(target === 'emailOTP'){
            this.emailOtpValue = value;
        }
    }

    async validateSMS_OTP(){
        this.showSpinner = true;
        if(!this.skippedSMSOTP){
            if(this.isOtpValidatedWithInCount){
                // verified SMS OTP and Send Email OTP
                await getOtpDetails({accountId : this.userRecord.AccountId})
                .then(getOTPResults=>{
                    if(getOTPResults.length > 0){
                        if(getOTPResults[0].BrokerLoginOTPNumber__c === this.smsOtpValue){
                            this.isNeedToClearSetInterval = true;
                            this.isSMSVerified = true;
                            if(this.isDomesticEmailTrue || this.isINTLEmailTrue){
                                this.sentEmailOTP_Utility();
                            }else{
                                this.skippedEmilOTP = true;
                                this.submitBankDetails();
                            }
                        }else {
                            this.showSpinner = false;
                            this.showToast('Validation Failed', 'SMS OTP is not Matched', 'error');
                        }
                    }else {
                        this.showSpinner = false;
                        this.showToast('Time out', 'Please Resend the OTP', 'error');
                    }       
                }).catch(error=>{
                    this.showSpinner = false;
                    this.showToast('Validation Failed', 'An Unexpected Error occured while validating SMS OTP', 'error');
                })
            }else{
                this.showSpinner = false;
                this.showToast('Time out', 'Please Resend the OTP', 'error');
            }
        }else{
            if(this.isDomesticEmailTrue || this.isINTLEmailTrue){
                this.sentEmailOTP_Utility();
            }else{
                this.submitBankDetails();
            }
        }
    }

    sentEmailOTP_Utility(){
        sentEmailOTP({ accountId : this.userRecord.AccountId, type : 'email'})
        .then(sentEmailOTPResults=>{
            if(sentEmailOTPResults == 'success'){
                this.showSpinner = false;
                this.isNeedToClearSetInterval = false;
                this.countDownUtlityFunction();
                this.showToast('Success', 'Your Email OTP has been Sent Successfully', 'success');
            }else{
                this.showSpinner = false;
                this.showToast('Error', 'An Unexpected Error occured while Sending the Email', 'error');
            }
        }).catch(error=>{
            this.showSpinner = false;
            this.showToast('Error', error.body.message, 'error');
        })
    }

    async validateEmailOTP_AndFinalSubmit(){
        // Verfied and Submit Data to Salesforce and Run Approval Process to Ireana to Apporve and Reject
        this.showSpinner = true;
        if(this.isOtpValidatedWithInCount){
            await getOtpDetails({ accountId : this.userRecord.AccountId })
            .then(getOTPResults=>{
                if(getOTPResults.length > 0){
                    if(getOTPResults[0].BrokerLoginOTPNumber__c === this.emailOtpValue){
                        this.isEmailVerified = true;
                        if(this.isSMSVerified){
                            this.submitBankDetails();
                        }
                    }else{
                        this.showSpinner = false;
                        this.showToast('Validation Failed', 'Email OTP is not Matched', 'error');
                    }
                }else{
                    this.showSpinner = false;
                    this.showToast('Time out', 'Please Resend the OTP', 'error');
                }
            }).catch(error=>{
                this.showSpinner = false;
                this.showToast('Validation Failed', error.body.message , 'error');
            })
        }else{
            this.showSpinner = false;
            this.showToast('Time out', 'Please Resend the OTP', 'error');
        }
    }

    submitBankDetails(event){
        this.showTimer = false;
        this.isNeedToClearSetInterval = true;
        let bankDetailUpdateCR = {};
            
        bankDetailUpdateCR['bankName'] = this.bankName; 
        bankDetailUpdateCR['bankBranch'] = this.bankBranch;
        bankDetailUpdateCR['accountNumber'] = this.confirmAccountNumber;
        bankDetailUpdateCR['IBANNumber'] = this.confirmIBANNumber;
        bankDetailUpdateCR['swiftCode'] = this.swiftCode;
        // bankDetailUpdateCR['currency'] = this.selectedCurrency;
        bankDetailUpdateCR['beneficiaryName'] = this.beneficiaryName;
        bankDetailUpdateCR['country'] = this.selectedCountry;

        bankDetailsCRSubmit({ userRecord : this.userRecord, bankDetails : bankDetailUpdateCR})
        .then(submitBankResults=>{
            if(submitBankResults === 'success'){
                this.upload(this.files, this.userRecord.AccountId);
                this.showSpinner = false;
                this.showToast('Success', 'We have Successfully Registered your Request', 'success');
                this.closeOTPModal();
                this.closeModal();
                window.location.replace('user-profile/');
            }else{
                this.showSpinner = false;
                this.finalSubmittionError = true;
                this.showToast('Error', JSON.stringify(submitBankResults), 'error');
            }
        }).catch(error=>{
            this.finalSubmittionError = true;
            this.showSpinner = false;
            this.showToast('Error', error.body.message, 'error');
        })
    }

    resendOTPs(event) {
        this.showSpinner = true;
        let type = event.target.name;
        this.isNeedToClearSetInterval = true;
        this.emailOtpValue = '';
        this.smsOtpValue = '';
    
        resendOTP({ accountId : this.userRecord.AccountId, type : type})
        .then(resendOtpResult => {
            if(resendOtpResult === 'success'){
                this.showSpinner = false; 
                this.isNeedToClearSetInterval = false;
                this.countDownUtlityFunction();
                this.showToast('Success', 'Your '+type+' OTP has been Resent Successfully', 'success')
            }else{
                this.showToast('Error', 'An Unexpected Error occured while Sending '+ type + ' OTP', 'error');
            }
        })
        .catch(error => {
            this.showSpinner = false;
            this.showToast('Error', error.body.message, 'error');
        });
    }

    countDownUtlityFunction(){
        this.showTimer = true;
        let remainingSeconds = this.countDown;
        this.isOtpValidatedWithInCount = true;

        var intrvalCount = setInterval(() => {
            remainingSeconds-- ;
            this.timerTextValue = `To generate next OTP wait for ${remainingSeconds} seconds.`
            if(remainingSeconds <= 0){
                clearInterval(intrvalCount);
                this.showTimer = false;
                this.isOtpValidatedWithInCount = false; 
            }else if(this.isNeedToClearSetInterval){
                clearInterval(intrvalCount);
                this.showTimer = false;
            }
        }, 1000);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    closeModal(){
        this.dispatchEvent(new CustomEvent('close',{detail:{isOpen:false}}));
    }

    closeOTPModal(){
        this.otpSection = false;
        this.isNeedToClearSetInterval = true;
        this.isSMSVerified = false;
        this.isEmailVerified = false;

        if(this.isEmailVerified || this.isSMSVerified){
            this.closeModal();
        }
    } 
}