/**
* @File Name : Base64Decoder.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 15, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 15, 2025 |   | Initial Version
**/

public class CreateFileBase64 {
	public class FlowInput {
		@InvocableVariable(required=true)
		public String base64Data;

		@InvocableVariable(required=true)
		public Id recordId;

		@InvocableVariable(required=true)
		public String fileName;
	}

    @InvocableMethod(label='Create File from Base64' description='Decodes Base64 and attaches file to a record')
    public static void decode(List<FlowInput> inputs) {
        List<ContentVersion> versions = new List<ContentVersion>();

        for (FlowInput input : inputs) {
            // Decode Base64 → Blob (SAFE)
            Blob fileBlob = EncodingUtil.base64Decode(input.base64Data);

            ContentVersion cv = new ContentVersion();
            cv.Title = input.fileName;
            cv.PathOnClient = '/' + input.fileName;
            cv.FirstPublishLocationId = input.recordId;
            cv.VersionData = fileBlob;
            cv.IsMajorVersion = true;
            versions.add(cv);
        }

        if (!versions.isEmpty()) {
            insert versions;
        }
    }
}