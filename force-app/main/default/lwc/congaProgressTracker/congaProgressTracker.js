import { LightningElement, api, track } from 'lwc';
import getStatusAndDownload from '@salesforce/apex/CONGAServicesFactory.getStatusAndDownload';

export default class CongaProgressTracker extends LightningElement {
  @api correlationId;
  @api recordId;
  @track status = 'Pending';
  @track downloadUrl = '';
  @track errorMessage = '';
  pollingInterval;
  progressValue = 10;

  get isInProgress() {
    return this.status !== 'Completed' && !this.downloadUrl && !this.errorMessage;
  }

  connectedCallback() {
    this.startPolling();
  }

  disconnectedCallback() {
    clearInterval(this.pollingInterval);
  }

  startPolling() {
    this.pollingInterval = setInterval(() => {
      this.checkStatus();
      this.progressValue = (this.progressValue + 10) % 100;
    }, 3000);
  }
  handleDownload() {
  window.open(this.downloadUrl, '_blank');
}

  checkStatus() {
    getStatusAndDownload({ correlationId: this.correlationId, recordId: this.recordId })
      .then(result => {
        console.log(result);
        this.status = result.status;
        if (result.status === 'Completed') {
          this.downloadUrl = result.downloadUrl;
          clearInterval(this.pollingInterval);
        } else if (result.status === 'Error') {
          this.errorMessage = result.errorMessage;
          clearInterval(this.pollingInterval);
        }
      })
      .catch(error => {
        this.errorMessage = error.body ? error.body.message : error.message;
        clearInterval(this.pollingInterval);
      });
  }
}