// ------------------------------------------------------------------------------
// Copyright (c) 2014 Microsoft Corporation
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
// ------------------------------------------------------------------------------

package appInstance.remoteRepo.onedrive.sdk.com.microsoft.live;

/**
 * Represents any functionality related to uploads that works with the Live Connect
 * Representational State Transfer (REST) API.
 */
public interface LiveUploadOperationListener {

    /**
     * Called when the associated upload operation call completes.
     *
     * @param operation The {@link LiveOperation} object.
     */
    void onUploadCompleted(LiveOperation operation);

    /**
     * Called when the associated upload operation call fails.
     *
     * @param exception The error returned by the REST operation call.
     * @param operation The {@link LiveOperation} object.
     */
    void onUploadFailed(LiveOperationException exception, LiveOperation operation);

    /**
     * Called arbitrarily during the progress of the upload request.
     *
     * @param totalBytes     The total bytes downloaded.
     * @param bytesRemaining The bytes remaining to download.
     * @param operation      The {@link LiveOperation} object.
     */
    void onUploadProgress(int totalBytes, int bytesRemaining, LiveOperation operation);
}
