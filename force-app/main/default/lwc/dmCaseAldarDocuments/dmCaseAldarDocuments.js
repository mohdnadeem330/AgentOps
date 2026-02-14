import { LightningElement, api, track, wire } from 'lwc';
import aldarDocuments from '@salesforce/apex/dmCaseDocumentsHandler.getAldarDocuments';
import updateDocument from '@salesforce/apex/dmCaseDocumentsHandler.updateDocument';
import generateEmailContent from '@salesforce/apex/dmCaseDocumentsHandler.generateEmailContent';
import updateDocumentVisibility from '@salesforce/apex/dmCaseDocumentsHandler.updateDocumentVisibility';
import { NavigationMixin } from 'lightning/navigation';
import createDoc from '@salesforce/apex/dmCaseDocumentsHandler.createDocument';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEmail from '@salesforce/apex/dmCaseDocumentsHandler.sendEmail';
import { deleteRecord } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/ldsUtils';
import ExternalStyleNew from '@salesforce/resourceUrl/ExternalStyleNew';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';
import CASE_TYPE from "@salesforce/schema/Case.Type";
import getLicenseeEmail from '@salesforce/apex/dmCaseDocumentsHandler.getLicenseeEmail';


export default class DmCaseAldarDocuments extends NavigationMixin(LightningElement) {
    @api recordId;
    showDocRecModal = false;
    sObjectLookupApiname = 'Case__c';
    @track docRecords = [];
    noDocuments = false;
    @track recordTypeId;
    showOtherName = false;
    docObj = new Object();
    showSpinner = false;
    showEmailPopup = false;
    btnDisable = false;
    showSpinners = false;
    showAddDoc = false;
    signedDocType = '';
    @track emailSubject = ''; // ==== CHANGE START Neelesh
    @track ccEmail = '';
    @track bccEmail = '';
    @track emailTo = '';
    @track licenseeEmail = '';
    @track emailBody = '';
    @track isBodyEditable = false;
    @track editableEmailBody = '';
   // ==== CHANGE END Neelesh

    // ==== CHANGE START: Handle subject and body input ====

   /* handleToChange(event) {
    this.toEmail = event.target.value;
    }
    handleCcChange(event) {
        this.ccEmail = event.target.value;
    }
    handleBccChange(event) {
        this.bccEmail = event.target.value;
    }
        
    handleSubjectChange(event) {
        this.emailSubject = event.target.value;
    }*/

     handleEmailChange(event) {
        const field = event.target.name;
        const value = event.target.value;

        if (field === 'emailTo') {
            this.emailTo = value;
        } else if (field === 'emailCc') {
            this.ccEmail = value;
        } else if (field === 'emailBcc') {
            this.bccEmail = value;
        } else if (field === 'emailSubject') {
            this.emailSubject = value;
        }
    }

    handleBodyChange(event) {
       
        this.emailBody = event.detail.value;
    }
   


   enableEdit() {
        this.isBodyEditable = true;
        this.editableEmailBody = this.emailBody;
    }

    cancelEdit() {
        this.isBodyEditable = false;
        this.editableEmailBody = '';
    }

    validateMultipleEmails(inputField) {
        const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        const emails = inputField.value.split(',').map(email => email.trim()).filter(email => email !== '');

        const invalidEmails = emails.filter(email => !emailPattern.test(email));

        if (invalidEmails.length === 0) {
            inputField.setCustomValidity('');
        } else {
            inputField.setCustomValidity(`Invalid email(s): ${invalidEmails.join(', ')}`);
        }
        inputField.reportValidity();
    }

    hasRendered = false;

    renderedCallback() {
        if (!this.hasRendered) {
            this.hasRendered = true;
            this.fetchAldardocument();
        }
    }



   /* enableEdit() {
        this.isBodyEditable = true;

        // Convert HTML to plain text before showing in textarea
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = this.emailBody;
        const plainText = tempDiv.textContent || tempDiv.innerText || '';

        this.editableEmailBody = plainText;
    }*/

    handleEditableBodyChange(event) {
        this.editableEmailBody = event.detail.value; // ⚠️ use `event.detail.value` for rich text
    }

    
    saveEditedBody() {
        if (this.editableEmailBody && this.editableEmailBody.trim() !== '') {
            this.emailBody = this.editableEmailBody;
        }
        this.isBodyEditable = false;
    }
     // ==== CHANGE END Neelesh

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [CASE_TYPE]
    })
    caseRecord({ error, data }) {
        if (data) {
            const caseType = getFieldValue(data, CASE_TYPE);
            if (caseType === 'Temporary License Agreement') {
                this.showAddDoc = true;
            } else {
                this.showAddDoc = false;
            }
        } else if (error) {
            //console.error(error);
        }
    }

    get acceptedFormats() {
        return ['.pdf', '.png'];
    }
    get documentOptions() {
        return [
            { label: 'Attachments', value: 'Attachments' },
            { label: 'CAS', value: 'CAS' },
            { label: 'Customer TLA', value: 'Customer TLA' },
            { label: 'Evacuation Checklist', value: 'Evacuation Checklist' },
            { label: 'Letter/Transmittal', value: 'Letter/Transmittal' },
            { label: 'Plot Allocation Plan', value: 'Plot Allocation Plan' },
            { label: 'Signed CAS', value: 'Signed CAS' },
            { label: 'Signed TLA', value: 'Signed TLA' },
            { label: 'Temporary License Agreement', value: 'Temporary License Agreement' },
            { label: 'Others', value: 'Others' },
        ];
    }
    connectedCallback() {
        this.docObj.SObjectType = 'Document__c';
        this.docObj.Case__c = this.recordId;
        this.fetchAldardocument();
        this.fetchLicenseeEmail();
        Promise.all([
            loadStyle(this, ExternalStyleNew)
        ])
            .then(() => {
            })
            .catch(error => {
            });
    }
    handleRefresh() {
        this.fetchAldardocument();
    }
    fetchAldardocument() {
        this.showSpinners = true;
        try {
            aldarDocuments({ caseId: this.recordId })
                .then(result => {
                    if (result) {
                        result.forEach(item => {
                         
                            item.isCheck = false;
                            this.noDocuments = false;
                           
                            if (item.doc.DocumentType__c === 'Signed TLA' || item.doc.DocumentType__c === 'Signed CAS') {
                                item.showVersions = false;
                            } else if (item.versionCount > 1) {
                                item.showVersions = true;
                            } else {
                                item.showVersions = false;
                            }
                            if (Object.keys(item.contentVersion).length == 0)
                                item.availableDoc = false;
                            else
                                item.availableDoc = true;

                            if (item.doc.DocumentType__c === 'Temporary License Agreement' || item.doc.DocumentType__c === 'Signed TLA')
                                item.showEmailBtn = true;
                            else
                                item.showEmailBtn = false;
                        });
                        this.docRecords = result;
                         
                    } else {
                        this.noDocuments = true;
                    }
                    this.showSpinners = false;
                }).catch(error => {
                    //console.log(JSON.stringify(error));
                    this.showSpinners = false;
                });
        } catch (error) {
            //console.log(error.message);
        }
    }
    handleChange(event) {
        if (event.target.name == 'DocumentType__c') {
            if (event.target.value == 'Others') {
                this.showOtherName = true;
            } else {
                this.showOtherName = false;
                this.docObj.Other_Document_Name__c = '';
            }
        }
        this.docObj[event.target.name] = event.target.value;
    }
    createDocument() {
        this.btnDisable = true;
        this.showSpinner = true;

        if (this.docObj.DocumentType__c === 'CAS') {
            this.signedDocType = 'Signed CAS';
        } else if (this.docObj.DocumentType__c === 'Customer TLA') {
            this.signedDocType = 'Signed TLA';
        }else{
            this.signedDocType = '';
        }
        //changes done by Parag 16/05/2025
            if (
            this.docObj.DocumentType__c === 'DM PMC Review Comment Sheet' ||
            this.docObj.DocumentType__c === 'Invoice' ||
            this.docObj.DocumentType__c === 'Permit to Work'
        ) {
            this.docObj.AvailableForExternalUsers__c = true;
        }

        createDoc({ doc: this.docObj, recTypeDevName: 'CustomerDocument', signedDocType: this.signedDocType }) //Case_Document
            .then(data => {
                this.showDocRecModal = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'success',
                        message: 'Document has been created successfully.',
                        variant: 'success'
                    })
                );
                this.fetchAldardocument();
                this.showSpinner = false;
                this.btnDisable = false;
            })
            .catch(error => {
                this.showSpinner = false;
                this.btnDisable = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'error',
                        message: 'Unable to create document, please check with admin',
                        variant: 'error'
                    })
                );
                //console.log('error', JSON.stringify(error));
            });
    }
    handleUploadFinished(event) {
        const uploadedFile = event.detail.files[0];
        const docId = event.target.recordId;
        const doctype = event.target.dataset.doctype;

        if (uploadedFile) {
            updateDocumentVisibility({ documentId: docId,docType: doctype, caseId : this.recordId })
                .then(data => {
                    //console.log('Visibility Updated');
                })
                .catch(error => {
                    //console.log('Error -', JSON.stringify(error));
                });
        }
        this.fetchAldardocument();
    }

    showCreateDoc(event) {
        this.showDocRecModal = true;
    }
    closeDocRecModal() {
        this.showDocRecModal = false;
        this.showEmailPopup = false;
    }
    filePreview(event) {
        const fileId = event.target.dataset.id;
        const fileName = event.target.dataset.title;
        const documentType = event.target.dataset.type;

        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: event.target.dataset.id
            }
        })
    }
    updateDocumentHandler(event) {
        let docObj = new Object();
        docObj.SObjectType = 'Document__c';
        docObj.Id = event.target.dataset.id;
        docObj.AvailableForExternalUsers__c = event.target.checked;
        updateDocument({ doc: docObj })
            .then(data => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'success',
                        message: 'Document has been updated successfully.',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                console.log('Error -', JSON.stringify(error));
            });
    }
    async deleteDocumentHandler(event) {
        try {
            await deleteRecord(event.target.dataset.id);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Document has been deleted successfully.',
                    variant: 'success'
                })
            );
            this.fetchAldardocument();

        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error deleting record',
                    message: reduceErrors(error).join(', '),
                    variant: 'error'
                })
            );
        }
        /* deleteDocument({recId : event.target.dataset.id})
            .then(data => {
               this.fetchAldardocument();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'success',
                        message: 'Document has been deleted successfully.',
                        variant: 'success'
                    })
                );
            }).catch(error => {
                 console.log('Error -', JSON.stringify(error));
            }); */
    }
    viewDocument(event) {
        const documentId = event.target.dataset.id;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: 'Document__c',
                recordId: documentId,
                actionName: 'view',
            },
        }).then((url) => {
            window.open(url, "_blank");
        });
    }


    downloadDocument(event) {
        const docId = event.target.dataset.id;
        let fileName = event.target.dataset.name;
        let ext = event.target.dataset.ext;
        const url = "/sfc/servlet.shepherd/document/download/" + docId;
        const downloadLink = document.createElement('a');
        downloadLink.href = url;
        downloadLink.setAttribute('download', '');
        downloadLink.download = fileName + '.' + ext;
        downloadLink.click();

    }
    handleCheck(event) {
        let index = event.target.dataset.index;
        this.docRecords[index].isCheck = event.target.checked;

    }
    downloadAllDocs() {
        try {
            let fileIds = [];
            this.docRecords.forEach(item => {
                if (item.isCheck) {
                    fileIds.push(item.contentVersion.ContentDocumentId);
                }
            });
            if (fileIds.length > 0) {
                const url = "/sfc/servlet.shepherd/document/download/" + fileIds.toString().replace(',', '/');
                const downloadLink = document.createElement('a');
                downloadLink.href = url;
                downloadLink.setAttribute('download', '');
                downloadLink.click();
                this.docRecords.forEach(item => {
                    item.isCheck = false;
                });
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'warning',
                        message: 'Please choose at least one document for downloading.',
                        variant: 'warning'
                    })
                );
            }

        } catch (e) {
            //console.log(e.message)
        }
    }
   
    handleSendEmail(event) {
        this.documentId = event.target.dataset.id;
        this.docId = event.target.dataset.docid;
        this.docType = event.target.dataset.name;

        this.showSpinner = true;
        this.showEmailPopup = true;

        // Reset fields (optional but clean UX)
        this.emailSubject = '';
        this.emailBody = '';
        this.ccEmail = '';
        this.bccEmail = '';

        // Set default To field with licensee email
        getLicenseeEmail({ caseId: this.recordId })
            .then(email => {
                this.licenseeEmail = email;
                this.emailTo = email;
            })
            .catch(err => {
                console.error('Failed to load licensee email', err);
            });

        // If applicable, fetch email template
        if (this.docType === 'Temporary License Agreement' || this.docType === 'Signed TLA') {
            generateEmailContent({ documentId: this.documentId, caseId: this.recordId, docType: this.docType })
                .then(result => {
                    this.emailSubject = result.subject;
                    this.emailBody = result.body;

                    //setTimeout(() => {
                       // const rte = this.template.querySelector('lightning-input-rich-text');
                        //if (rte) {
                         //   rte.value = this.emailBody;
                        //}
                        //this.showSpinner = false;
                   // }, 100);
                   this.showSpinner = false;
                })
                .catch(error => {
                    this.showSpinner = false;
                    console.error('Error generating email:', error);
                });
        } else {
            this.showSpinner = false;
        }
    }

    validateEmailsBeforeSend() {
        const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        const toInput = this.template.querySelector('lightning-input[data-id="toEmail"]');
        const ccInput = this.template.querySelector('lightning-input[data-id="ccEmail"]');
        const bccInput = this.template.querySelector('lightning-input[data-id="bccEmail"]');

        let isValid = true;

        // Validate To (required, multiple comma separated emails)
        if (!this.emailTo || this.emailTo.trim() === '') {
            toInput.setCustomValidity('To email is required');
            isValid = false;
        } else {
            const emailTo = this.emailTo.split(',').map(e => e.trim()).filter(e => e);
            const invalidTo = emailTo.filter(email => !emailPattern.test(email));
            if (invalidTo.length > 0) {
                toInput.setCustomValidity(`Invalid To email(s): ${invalidTo.join(', ')}`);
                isValid = false;
            } else {
                toInput.setCustomValidity('');
            }
        }
        toInput.reportValidity();

        // Validate CC (optional multiple comma separated emails)
        if (this.ccEmail) {
            const ccEmails = this.ccEmail.split(',').map(e => e.trim()).filter(e => e);
            const invalidCc = ccEmails.filter(email => !emailPattern.test(email));
            if (invalidCc.length > 0) {
                ccInput.setCustomValidity(`Invalid CC email(s): ${invalidCc.join(', ')}`);
                isValid = false;
            } else {
                ccInput.setCustomValidity('');
            }
            ccInput.reportValidity();
        } else {
            ccInput.setCustomValidity('');
            ccInput.reportValidity();
        }

        // Validate BCC (optional multiple comma separated emails)
        if (this.bccEmail) {
            const bccEmails = this.bccEmail.split(',').map(e => e.trim()).filter(e => e);
            const invalidBcc = bccEmails.filter(email => !emailPattern.test(email));
            if (invalidBcc.length > 0) {
                bccInput.setCustomValidity(`Invalid BCC email(s): ${invalidBcc.join(', ')}`);
                isValid = false;
            } else {
                bccInput.setCustomValidity('');
            }
            bccInput.reportValidity();
        } else {
            bccInput.setCustomValidity('');
            bccInput.reportValidity();
        }

        return isValid;
    }

    // Change end by neelesh


    sendEmail() {
        if (!this.validateEmailsBeforeSend()) {
            return;
        }

     
        this.showSpinner = true;
        this.btnDisable = true;

        sendEmail({
            documentId: this.documentId,
            caseId: this.recordId,
            docType: this.docType,
            docId: this.docId,
            subject: this.emailSubject,
            body: this.emailBody,
            cc: this.ccEmail,
            bcc: this.bccEmail,
            to: this.emailTo
        })
        .then(() => {
            this.fetchAldardocument();

            // Show success toast first
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Email has been sent successfully.',
                    variant: 'success'
                })
            );

            // Now delay hiding modal and spinner slightly
            setTimeout(() => {
                this.showSpinner = false;
                this.btnDisable = false;
                this.showEmailPopup = false;
            }, 300); // Adjust timing if needed
        })
        .catch(error => {
            this.showSpinner = false;
            this.btnDisable = false;
            console.error(error);
        });
    }


  /*  connectedCallback() {
        this.fetchLicenseeEmail();
    }*/

    fetchLicenseeEmail() {
        getLicenseeEmail({ caseId: this.recordId }) // make sure `recordId` is set
            .then(result => {
                this.licenseeEmail = result;
            })
            .catch(error => {
                console.error('Error fetching licensee email', error);
            });
    }

}