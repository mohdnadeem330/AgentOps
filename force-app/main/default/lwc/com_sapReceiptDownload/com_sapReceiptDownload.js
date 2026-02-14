import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';


export default class FlowPdfPreview extends NavigationMixin(LightningElement) {
  // Flow passes the Base64 here
  @api base64Pdf;          // Text from Flow (the "results")
  @api fileName = 'SAP_Receipt.pdf';
  @api autoDownload = false; // set true in Flow if you want to force download
  @api recordId;            
  @api done = 'Back to record';

  pdfUrl;
  _done = false;

  renderedCallback() {
    if (this._done) return;
    if (!this.base64Pdf) return;

    try {
      const clean = this.stripDataPrefix(this.base64Pdf);
      const blob = this.base64ToBlob(clean, 'application/pdf');
      this.pdfUrl = URL.createObjectURL(blob);

      // Optional auto-download on load
      if (this.autoDownload) {
        this.forceDownload(this.pdfUrl, this.fileName);
      }
      this._done = true;
    } catch (e) {
      // Show a minimal inline error
      // (You can add a <lightning-formatted-text> error if you prefer)
      // eslint-disable-next-line no-console
      console.error('PDF decode failed', e);
    }
  }

  // Helpers
  stripDataPrefix(b64) {
    const i = b64.indexOf('base64,');
    return i > -1 ? b64.substring(i + 7) : b64.trim();
  }

  base64ToBlob(base64, mimeType) {
    const slice = 8192; // chunked to avoid memory spikes
    const byteChars = atob(base64);
    const len = byteChars.length;
    const chunks = Math.ceil(len / slice);
    const arrays = new Array(chunks);

    for (let i = 0, off = 0; i < chunks; i++, off += slice) {
      const size = Math.min(slice, len - off);
      const nums = new Array(size);
      for (let j = 0; j < size; j++) nums[j] = byteChars.charCodeAt(off + j);
      arrays[i] = new Uint8Array(nums);
    }
    return new Blob(arrays, { type: mimeType });
  }

  forceDownload(url, filename) {
    const a = document.createElement('a');
    a.href = url;
    a.download = filename || 'file.pdf';
    document.body.appendChild(a);
    a.click();
    a.remove();
  }

   redirectToRecordPage() {
    if (!this.recordId) {
      return;
    }
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.recordId,
        actionName: 'view'
      }
    });
  }
}