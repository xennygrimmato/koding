// THIS FILE IS AUTOMATICALLY GENERATED. DO NOT EDIT.

package glacier

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/client"
	"github.com/aws/aws-sdk-go/aws/client/metadata"
	"github.com/aws/aws-sdk-go/aws/request"
	"github.com/aws/aws-sdk-go/private/protocol/restjson"
	"github.com/aws/aws-sdk-go/private/signer/v4"
)

// Amazon Glacier is a storage solution for "cold data."
//
// Amazon Glacier is an extremely low-cost storage service that provides secure,
// durable, and easy-to-use storage for data backup and archival. With Amazon
// Glacier, customers can store their data cost effectively for months, years,
// or decades. Amazon Glacier also enables customers to offload the administrative
// burdens of operating and scaling storage to AWS, so they don't have to worry
// about capacity planning, hardware provisioning, data replication, hardware
// failure and recovery, or time-consuming hardware migrations.
//
// Amazon Glacier is a great storage choice when low storage cost is paramount,
// your data is rarely retrieved, and retrieval latency of several hours is
// acceptable. If your application requires fast or frequent access to your
// data, consider using Amazon S3. For more information, go to Amazon Simple
// Storage Service (Amazon S3) (http://aws.amazon.com/s3/).
//
// You can store any kind of data in any format. There is no maximum limit
// on the total amount of data you can store in Amazon Glacier.
//
// If you are a first-time user of Amazon Glacier, we recommend that you begin
// by reading the following sections in the Amazon Glacier Developer Guide:
//
//  What is Amazon Glacier (http://docs.aws.amazon.com/amazonglacier/latest/dev/introduction.html)
// - This section of the Developer Guide describes the underlying data model,
// the operations it supports, and the AWS SDKs that you can use to interact
// with the service.
//
// Getting Started with Amazon Glacier (http://docs.aws.amazon.com/amazonglacier/latest/dev/amazon-glacier-getting-started.html)
// - The Getting Started section walks you through the process of creating a
// vault, uploading archives, creating jobs to download archives, retrieving
// the job output, and deleting archives.
//The service client's operations are safe to be used concurrently.
// It is not safe to mutate any of the client's properties though.
type Glacier struct {
	*client.Client
}

// Used for custom client initialization logic
var initClient func(*client.Client)

// Used for custom request initialization logic
var initRequest func(*request.Request)

// A ServiceName is the name of the service the client will make API calls to.
const ServiceName = "glacier"

// New creates a new instance of the Glacier client with a session.
// If additional configuration is needed for the client instance use the optional
// aws.Config parameter to add your extra config.
//
// Example:
//     // Create a Glacier client from just a session.
//     svc := glacier.New(mySession)
//
//     // Create a Glacier client with additional configuration
//     svc := glacier.New(mySession, aws.NewConfig().WithRegion("us-west-2"))
func New(p client.ConfigProvider, cfgs ...*aws.Config) *Glacier {
	c := p.ClientConfig(ServiceName, cfgs...)
	return newClient(*c.Config, c.Handlers, c.Endpoint, c.SigningRegion)
}

// newClient creates, initializes and returns a new service client instance.
func newClient(cfg aws.Config, handlers request.Handlers, endpoint, signingRegion string) *Glacier {
	svc := &Glacier{
		Client: client.New(
			cfg,
			metadata.ClientInfo{
				ServiceName:   ServiceName,
				SigningRegion: signingRegion,
				Endpoint:      endpoint,
				APIVersion:    "2012-06-01",
			},
			handlers,
		),
	}

	// Handlers
	svc.Handlers.Sign.PushBack(v4.Sign)
	svc.Handlers.Build.PushBackNamed(restjson.BuildHandler)
	svc.Handlers.Unmarshal.PushBackNamed(restjson.UnmarshalHandler)
	svc.Handlers.UnmarshalMeta.PushBackNamed(restjson.UnmarshalMetaHandler)
	svc.Handlers.UnmarshalError.PushBackNamed(restjson.UnmarshalErrorHandler)

	// Run custom client initialization if present
	if initClient != nil {
		initClient(svc.Client)
	}

	return svc
}

// newRequest creates a new request for a Glacier operation and runs any
// custom request initialization.
func (c *Glacier) newRequest(op *request.Operation, params, data interface{}) *request.Request {
	req := c.NewRequest(op, params, data)

	// Run custom request initialization if present
	if initRequest != nil {
		initRequest(req)
	}

	return req
}