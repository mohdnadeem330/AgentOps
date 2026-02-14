import { LightningElement, api, track } from 'lwc';
import getFiles from '@salesforce/apex/ContentVersionService.returnFiles';
import createFiles from '@salesforce/apex/ManageRequestController.createFiles';
import getRelatedFilesByCaseId from '@salesforce/apex/ManageRequestController.getRelatedFilesByCaseId';
import getAgencyName from '@salesforce/apex/ManageRequestController.getAgencyName';
import updateBrokerRecords from '@salesforce/apex/ManageRequestController.updateBrokerRecords';
import getURLPath from '@salesforce/apex/ManageRequestController.getURLPath';
import getConstant from '@salesforce/apex/Utilities.getConstant';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getAttachmentURL from '@salesforce/apex/CaseCommentsService.getAttachmentURL';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';

import quarterlyLimit from "@salesforce/apex/ManageRequestController.quarterlyLimitNew";
import getBufferDays from "@salesforce/apex/ManageRequestController.getBufferDaysBrokerClassification";
import checkForExistingRequestForQuarter from "@salesforce/apex/ManageRequestController.checkForExistingRequestForQuarter";


export default class BrokerRequestViewScreen extends NavigationMixin(LightningElement) 
{

    @api recordId;
    @api recordType;
    @api approvalStatus;
    @api marketingRecordType;
    @api eventRecordType;
    @api capturedData = {};

    @track bufferDaysReceived;
    @track displayBrokerRecord = {};
    @track eventFields;
    @track isMarketingFields = false;
    @track marketingRejectedFields = false;
    @track isEventFields = false;
    @track eventRejectedFields = false;
    @track uploadedFiles = [];
    @track fileNamesList = [];
    @track fileNames;
    @track locationValue;
    @track startDateValue;
    @track endDateValue;
    @track downloadURL;
    @track urlPathPrefix;
    @track showUplod = false;
    @track taxAmountValue;
    @track invoiceValue;
    @track agencyId;
    @track commentsValue;
    @track invoiceAmountValue;
    @track displaySodicAmount = false;
    @track sodicInvoiceAmountvalue;
    @track agencyValue;
    @track filesList = [];
    @track totalAmountValue;
    @track showSpinner = false;
    @track helpText = '';
    @track acceptFileTypeList = [];
    @track taxAmountdisabled = false;
    @track taxAmountRequired = true;

    uploadeFileIcon = resourcesPath + "/ALDARResources/svg/UploadedFileIcon.svg";
    deleteFileIcon = resourcesPath + "/ALDARResources/svg/DeleteFileIcon.svg";

    async connectedCallback()
    {
        this.displayBrokerRecord = JSON.parse(JSON.stringify(this.capturedData));
        if (this.recordType == 'Event Request' && (this.approvalStatus == 'Approved' || this.approvalStatus == 'Approval Pending')) {
            this.isEventFields = true;
        } else if (this.recordType == 'Event Request' && this.approvalStatus == 'Rejected') {
            this.eventRejectedFields = true;
            this.isEventFields = true;
        } else if (this.recordType == 'Marketing Reimbursement' && this.approvalStatus == 'Approved' || this.approvalStatus == 'Approval Pending') {
            this.isMarketingFields = true;
        } else if (this.recordType == 'Marketing Reimbursement' && this.approvalStatus == 'Rejected') {
            this.marketingRejectedFields = true;
            this.isMarketingFields = true;
        }

        if (this.recordType == 'Marketing Reimbursement') {
            this.commentsValue = '';
            this.invoiceValue = this.displayBrokerRecord.Invoice;
            this.invoiceDateValue = this.displayBrokerRecord.InvoiceDate;
            this.taxAmountValue = this.displayBrokerRecord.TaxAmount;
            this.invoiceAmountValue = this.displayBrokerRecord.InvoiceAmount;
            this.sodicInvoiceAmountvalue = this.displayBrokerRecord.SodicInvoiceAmount;
            //this.displaySodicAmount = parseInt(this.sodicInvoiceAmountvalue) == 0 || this.sodicInvoiceAmountvalue == undefined ? 'FALSE': 'true';
            this.totalAmountValue = this.displayBrokerRecord.TotalAmount;
        } else {
            this.commentsValue = '';
            this.startDateValue = this.displayBrokerRecord.StartDate;
            this.endDateValue = this.displayBrokerRecord.EndDate;
            this.locationValue = this.displayBrokerRecord.Location;
        }

        this.showSpinner = true;
        await getAgencyName().then(result => {
            var data = [];
            data = result;
            this.agencyId = data.Id;
            this.agencyValue = data.Name;
            this.vatRegisterNumber  = data.UAEVATRegisterNumber__c;
            this.showSpinner = false;
        }).catch(error => {
            // console.log('error' + JSON.stringify(error));
            this.showSpinner = false;
        });

        // If the agency is not registered with VAT then disable the field
        if(this.vatRegisterNumber == '' || this.vatRegisterNumber == null){
            this.taxAmountdisabled = true;
            this.taxAmountRequired = false;
        }

        if(this.sodicInvoiceAmountvalue == '' || this.sodicInvoiceAmountvalue == null){
            this.displaySodicAmount = false;
        }else{
            this.displaySodicAmount = true;
        }

        getConstant({
            messageName: 'FileAcceptedManageRequest'
        }).then(result => {
            var acceptedFile = result.ConstantValue__c;
            if (acceptedFile != undefined && acceptedFile != null && acceptedFile != '') {
                this.helpText = 'Kindly upload files in the format ' + acceptedFile;

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

        this.displaylistOfFiles();
    }


    async displaylistOfFiles(event) {
        this.showSpinner = true;
        await getURLPath().then(data => {
            this.urlPathPrefix = data;
            this.downloadURL = 'https://' + location.host + '/' + this.urlPathPrefix + '/';
            this.showSpinner = false;
        }).catch(error => {
            // console.log('error ====> ' + error);
            this.showSpinner = false;
        })

        this.showSpinner = true;
        await getRelatedFilesByCaseId({
            recordId: this.recordId
        }).then(result => {
            // console.log('url>>>' + this.downloadURL);
            let resultdata = JSON.parse(JSON.stringify(result));
            this.filesList = [];
            for (let item of resultdata) {
                let tMap = {
                    "label": item.Title,
                    "value": item.ContentDocumentId,
                    "type": item.ContentDocument.FileType,
                    "latestId": item.ContentDocument.LatestPublishedVersionId,
                    "url": this.downloadURL + 'sfc/servlet.shepherd/document/download/' + item.ContentDocumentId
                };
                this.filesList.push(tMap);
            }
            this.showSpinner = false;
            // console.log('filesList>>>', JSON.stringify(this.filesList));
        }).catch(error => {
            // console.log(error);
            this.showSpinner = false;
        })
    }

    onFileUpload(event) {

        let files = event.target.files;
        // console.log('files' + files);
        if (files.length > 0 && this.fileNamesList.length < 5) {
            var acceptFileList = [];
            for (let i = 0; i < files.length; i++) {
                let filePieces = files[i].name.split('.');
                let fileType = filePieces[filePieces.length - 1].trim();
                
                if (this.acceptFileTypeList.includes(fileType)) {
                    acceptFileList.push(files[i]);
                }
            }
            if (acceptFileList.length > 0) {
                let filesName = '';

                for (let i = 0; i < acceptFileList.length; i++) {
                    let file = acceptFileList[i];
                    // console.log('140   ********************8');
                    filesName = filesName + file.name + ',';
                    // console.log('filenames' + filesName);
                    let freader = new FileReader();
                    freader.onload = f => {
                        let base64 = 'base64,';
                        let content = freader.result.indexOf(base64) + base64.length;
                        let fileContents = freader.result.substring(content);
                        this.uploadedFiles.push({
                            Title: file.name,
                            VersionData: fileContents
                        });
                    };
                    freader.readAsDataURL(file);
                }

                this.fileNames = filesName.slice(0, -1);

                this.fileNamesList.push(this.fileNames);
            }
        }else{
            this.showToast('Error', 'Cannot upload more than 5 files', 'error', 'dismissable');
        }
    }

    get acceptedFormats() {
        var acceptFormatList = [];
        for (let i = 0; i < this.acceptFileTypeList.length; i++) {
            acceptFormatList[i] = '.' + this.acceptFileTypeList[i];
        }

        return acceptFormatList;
    }

    handleChangeFields(event) {
        if (event.target.name == 'Comments') {
            this.commentsValue = event.target.value;
            // console.log('commentsValue' + this.commentsValue);
        }

        if (event.target.name == 'Location') {
            this.locationValue = event.target.value;
            // console.log('locationValue' + this.locationValue);
        }

        if (event.target.name == 'StartDate') {
            this.startDateValue = event.detail.value;
            // console.log('startDateValue' + this.startDateValue);
        }

        if (event.target.name == 'EndDate') {
            this.endDateValue = event.target.value;
            // console.log('end' + this.endDateValue);
        }

        if (event.target.name == 'InvoiceAmount') {
            this.invoiceAmountValue = event.target.value == '' ? 0 : event.target.value;
            //this.totalAmountValue = (this.invoiceAmountValue ? parseInt(this.invoiceAmountValue) : 0)+ (this.taxAmountValue ? parseInt(this.taxAmountValue) : 0) ;
            // console.log('invoiceAmountValue' + this.invoiceAmountValue);
        }

        if (event.target.name == 'TaxAmount') {
            this.taxAmountValue = event.target.value;
            //this.totalAmountValue = (this.taxAmountValue ? parseInt(this.taxAmountValue) : 0) + (this.invoiceAmountValue ? parseInt(this.invoiceAmountValue) : 0);
            // console.log('commentaxAmountValuetsValue' + this.taxAmountValue);
        }

        if (event.target.name == 'Invoice') {
            this.invoiceValue = event.target.value;
            // console.log('invoiceValue' + this.invoiceValue);
        }

        if (event.target.name == 'InvoiceDate') {
            this.invoiceDateValue = event.target.value;
            // console.log('invoiceDateValue' + this.invoiceDateValue);
        }
        if (event.target.name == 'IncludeSodic') {
            var sodicChecked = event.target.checked;
            if(sodicChecked){
                this.displaySodicAmount = true;
            }else{
                this.displaySodicAmount = false;
                this.sodicInvoiceAmountvalue = 0;
                this.handleAmtVal_CalTaxAmt(event);
            }
        }
        if (event.target.name == 'SodicInvoiceAmount') {
            this.sodicInvoiceAmountvalue = event.target.value == '' ? 0 : event.target.value;
        }

        /*
        if (this.taxAmountValue && this.invoiceAmountValue) {
            this.totalAmountValue = parseInt(this.taxAmountValue) + parseInt(this.invoiceAmountValue);
            // console.log('ttll>>l' + this.totalAmountValue);
        }
        */
    }

    UplodFile() {
        // console.log('inside uplod');
        if (!this.uploadedFiles || this.uploadedFiles.length === 0) {
            this.showToast('Error', 'Please Attach Files', 'error', 'dismissable');
            // console.log('Uplodd file>>>>');
        } else {
            this.showUplod = true;

            this.showSpinner = true;
            createFiles({
                filesToInsert: this.uploadedFiles, recordId: this.recordId
            }).then(data => {
                // console.log('202>>>' + JSON.stringify(data));
                this.showToast('Success', 'File/s Uploaded Successfully', 'success', 'dismissable');

                this.showSpinner = false;
                this.getFilesData(data);
                this.fileNamesList = [];
            }).catch(error => {
                // console.log('error>>>', JSON.stringify(error));
                this.showSpinner = false;

            });
        }
    }

    getFilesData(lstIds) {
        this.showSpinner = true;
        getFiles({
            lstFileIds: lstIds
        }).then(data => {
            // console.log('inside get files data');
            data.forEach((record) => {
                record.FileName = '/' + record.Id;
            });

            this.data = data;
            this.displaylistOfFiles();
            this.showSpinner = false;

            //this.dispatchEvent(new CustomEvent('callgetdata',{detail:' '}));
        }).catch(error => {
            // console.log('error ====> ' + JSON.stringify(error));
            this.showSpinner = false;
        })
    }

    removeFile(event) {
        var index = event.currentTarget.dataset.id;
        this.uploadedFiles.splice(index, 1);
        this.fileNamesList.splice(index, 1);
    }


    async updateRecord()
    {
        let requestType = '';
        let isError = false;
        if (this.recordType == 'Marketing Reimbursement') 
        {
            if (this.invoiceAmountValue && this.invoiceValue 
                && this.invoiceDateValue && this.totalAmountValue)
            {
                let today = new Date().toISOString().slice(0, 10);
                
                
                if (!isError)
                {
                    this.showSpinner = true;
                    await quarterlyLimit({
                        accountId: this.agencyId,
                        recordTypeId: this.marketingRecordType,
                        invoiceDate: this.invoiceDateValue
                    }).then(result => {
                        this.showSpinner = false;
                        console.log('quarterResult' + JSON.stringify(result));
                        this.sodicQuarterlyLimitVal = result.sodicQuarterlyLimit != null ? result.sodicQuarterlyLimit : 0;
                        this.quarterlyLimitVal = result.quarterlyLimit != null ? result.quarterlyLimit : 0;
                        this.consumeLimitVal = result.consumeLimit && result.consumeLimit != null ? result.consumeLimit : 0;
                        this.remainingLimitVal = this.quarterlyLimitVal - this.consumeLimitVal;

                        if (this.remainingLimitVal < 0 || this.remainingLimitVal < this.invoiceAmountValue) {
                            isError = true;
                            this.showToast('Error', 'You have exceeded your quarterly limit', 'error');
                        }
                        if(this.sodicQuarterlyLimitVal < this.sodicInvoiceAmountvalue){
                            isError = true;
                            this.showToast('Error', 'You have exceeded your sodic quarterly limit', 'error');
                        }
                        
                    })
                    .catch(error => {
                        // TODO Error handling
                        console.log('error' + JSON.stringify(error));
                    });
                }

                if (!isError)
                {
                    requestType = 'Marketing Reimbursement';
                    // console.log('inside market update');
                    var updateReq = {
                    'sobjectType': 'BrokerRequest__c',
                    'Id': this.recordId,
                    'Remark__c': this.commentsValue,
                    'Invoice__c': this.invoiceValue,
                    //'InvoiceDate__c': this.invoiceDateValue,
                    'TaxAmount__c': this.taxAmountValue == undefined ? 0 : this.taxAmountValue,
                    'InvoiceAmount__c': this.invoiceAmountValue,
                    'SodicInvoiceAmount__c': this.sodicInvoiceAmountvalue,
                    'RecordTypeId': this.marketingRecordType,
                    'TotalAmount__c': this.totalAmountValue.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","),
                    'ApprovalStatus__c': 'Draft'
                    }
                }

            }
            else{
                isError = true;
                this.showToast('Error', 'Please fill required fields', 'error', 'dismissable');
            }
        }
        else if ((this.recordType == 'Event Request')) {
            requestType = 'Event';
            // console.log('inside event update');
            var updateReq = {
                'sobjectType': 'BrokerRequest__c',
                'Remark__c': this.commentsValue,
                'Id': this.recordId,
                'StartDate__c': this.startDateValue,
                'EndDate__c': this.endDateValue,
                'RecordTypeId': this.eventRecordType,
                'Location__c': this.locationValue,
                'ApprovalStatus__c': 'Draft'
            }
        }


        if(!isError)
        {
            this.showSpinner = true;
            await updateBrokerRecords({
                updateReq: updateReq
            }).then(result => {
                console.log(result);
                this.dispatchEvent(new CustomEvent('callgetdata', { detail: '' }));
                this.showToast('Success', 'Record Updated Successfully', 'success', 'dismissable');
                this.showSpinner = false;
                this.closeModal();
            }).catch(error => {
                let err = error;
                //this.showToast('Error', 'Some Error Occured, Contact Admin', 'error', 'dismissable');
                // console.log('error>>>>>>>>>>>>>>>>>>>>249' + JSON.stringify(err));
                this.showSpinner = false;
            });
        }


    }





    closeModal() {
        this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false } }));
    }

    handleValidation(event) {
        // console.log('handleValidation');
        //  let getinvoicedate = this.template.querySelector('.invoicedate');
        let today = new Date().toISOString().slice(0, 10);
        // console.log('today>>' + today);

        var invDate = new Date(this.invoiceDateValue);
        // console.log('invoice date' + invDate);

        var tdate = new Date(today);
        // console.log('tdate>>' + tdate);

        const diffTime = Math.abs(tdate - invDate);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        // console.log(diffTime + " milliseconds");
        // console.log(diffDays + " >days");

        if (diffDays > 30) {
            // console.log('240');
            this.showToast('Error', 'Invoice date should be within 30 days', 'error', 'dismissable');

        }

        //end date logic
        var startDate = new Date(this.startDateValue);
        var endDate = new Date(this.endDateValue);

        if ((Date.parse(startDate) > Date.parse(endDate))) {
            this.showToast('Error', 'End date should be in future', 'error');
        }

      }

    handleInvoiceDateMRvalidation()
    {
            let today = new Date().toISOString().slice(0, 10);
            if ((Date.parse(today) < Date.parse(this.invoiceDateValue))) 
            {
                this.showToast('Error', 'Invoice date cannot be in future', 'error');
            }
            /*
            else if(this.invoiceDateValue != null)
            {
                // Below logic finds the quarter, start date and end date of the quarter
                // And checks if created date is with in the range
                let invoiceDate = new Date(this.invoiceDateValue);
                let quarterValue = this.getQuarter(invoiceDate);

                let startDate = new Date(this.getStartingDay(quarterValue, invoiceDate));
                const finalStartDate = new Date(startDate);
                // Add 3 months to start date
                let startDateAddDays = startDate.setMonth(startDate.getMonth() + 3);
                let finalEndDate = new Date(startDateAddDays);
                // Add bufferDays additionally
                finalEndDate.setDate(finalEndDate.getDate() + this.bufferDaysReceived);

                //alert('finalStartDate---->>>'+finalStartDate.toLocaleDateString());
                //alert('finalEndDate---->>>'+finalEndDate.toLocaleDateString());
                // Date: '2023-03-15'
                let tdate = new Date();
                //alert('currentDate:'+tdate.toLocaleDateString());
                

                if( tdate.getTime() >= finalStartDate.getTime()
                && tdate.getTime() <= finalEndDate.getTime()){}
                else{
                    this.showToast('Error', 'Date elapsed and Invoice cannot be requested', 'error');
                }
            }
            */
      }

    getQuarter(date) {
        // Get the month of the given date (0 - 11)
        const month = date.getMonth();
        // Determine the quarter based on the month
        if (month <= 2) {
          return 1; // Q1: January - March
        } else if (month <= 5) {
          return 2; // Q2: April - June
        } else if (month <= 8) {
          return 3; // Q3: July - September
        } else {
          return 4; // Q4: October - December
        }
      }
      
    getStartingDay(quarter, invDate) {
        // Determine the month and year based on the quarter
        let month, year;
        if (quarter === 1) {
          month = 0; // January
          year = invDate.getFullYear();
        } else if (quarter === 2) {
          month = 3; // April
          year = invDate.getFullYear();
        } else if (quarter === 3) {
          month = 6; // July
          year = invDate.getFullYear();
        } else if (quarter === 4) {
          month = 9; // October
          year = invDate.getFullYear();
        } else {
          return null; // Invalid quarter number
        }
      
        // Create a new Date object with the determined month and year
        const date = new Date(year, month);
        return date;
      }

    handleAmtVal_CalTaxAmt(event)
    {
        if(parseInt(event.target.value) < 0){
            event.target.value = 0;
        }
        if(this.taxAmountRequired && !this.displaySodicAmount){
            let taxAmountPercent = (parseInt(this.invoiceAmountValue)/100)*5;
            let finalCalculatedTaxAmtLimit = taxAmountPercent.toFixed(2);
            this.taxAmountValue = finalCalculatedTaxAmtLimit;
            this.totalAmountValue = parseInt(this.invoiceAmountValue) + parseFloat(finalCalculatedTaxAmtLimit);
        }
        else if(this.taxAmountRequired && this.displaySodicAmount){
            let totalAmountWithSodic = parseInt(this.invoiceAmountValue) + parseInt(this.sodicInvoiceAmountvalue);
            let taxAmountPercent = (parseInt(totalAmountWithSodic)/100)*5;
            let finalCalculatedTaxAmtLimit = taxAmountPercent.toFixed(2);
            this.taxAmountValue = finalCalculatedTaxAmtLimit;
            this.totalAmountValue = parseInt(totalAmountWithSodic) + parseFloat(finalCalculatedTaxAmtLimit);
        }else{
            this.taxAmountValue = 0;
            this.totalAmountValue = parseInt(this.invoiceAmountValue) + 0;
        }
    }

    showToast(title, message, varaint, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: varaint,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    previewHandler(event) {
        // console.log('previewHandler>>>recId' + this.recordId);
        var contentVersionId = event.target.dataset.latestid;
        // console.log('contentVersionId>>>' + contentVersionId);

        this.showSpinner = true;
        getAttachmentURL({
            csId: this.recordId,
            cvId: contentVersionId
        }).then(result => {
            // console.log('result>>>' + JSON.stringify(result));

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: result.DistributionPublicUrl
                }
            }, false);
            this.showSpinner = false;
        }).catch(error => {
            // console.error('error>>>', JSON.stringify(error));
            this.showSpinner = false;
        })
    }
}