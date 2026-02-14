import { LightningElement, api, track } from 'lwc';
//import updateStatus from '@salesforce/apex/CommissionsReportController.TestmethidForCD';
import getCommissionTrail from '@salesforce/apex/QuarterlyBrokerCommissionController.getCommissionTrail';
import updateStatus from '@salesforce/apex/QuarterlyBrokerCommissionController.updateStatus';
import { NavigationMixin } from 'lightning/navigation';

export default class ManageQuarterlyInvoiceModal extends NavigationMixin(LightningElement) {
    @api commissionRecordId;
    @api enableAction;
    brokerInvoiceURL;
    urlPrefix = '/QuarterlyInvoicePDF?invoiceId=';
    commentRequired = false;
    @track showSpinner = false;
    comments = '';


    connectedCallback() {
        this.showSpinner = true;
        this.brokerInvoiceURL = '..' + this.urlPrefix + this.commissionRecordId; `url(..${this.urlPrefix + this.commissionRecordId})`;
        console.log('this.brokerInvoiceURL', this.brokerInvoiceURL);
        this.showSpinner = false;
        this.getTrails();
    }
    getTrails() {
        getCommissionTrail({ recordId: this.commissionRecordId })
            .then(data => {
                this.comments = data;
            })
            .catch(error => {
                console.error(error);
            });
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false } }));
    }
    handleDownload() {
        window.open(this.brokerInvoiceURL + '&renderVal=pdf', "_blank");
    }

    handleStatusChange(event) {
        this.showSpinner = true;
        var statusValue = event.target.name;
        if (statusValue === 'Rejected') {
            this.template.querySelectorAll('.inputComments').forEach(element => {
                element.reportValidity();
            });
            this.commentRequired = true;

        } else {
            this.commentRequired = false;
        }

        if (!this.commentRequired || (this.template.querySelector('.inputComments').value && this.template.querySelector('.inputComments').value != '')) {

            if (statusValue) {
                updateStatus({ recordId: this.commissionRecordId, statusValue: statusValue, comment: this.template.querySelector('.inputComments').value })
                    .then(data => {
                        this.dispatchEvent(new CustomEvent('closeandupdate', { detail: { isOpen: false } }));
                    })
                    .catch(error => {
                        console.error(error);
                        this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false } }));
                    });
            }
        } else {
            this.showSpinner = false;
        }


    }
}