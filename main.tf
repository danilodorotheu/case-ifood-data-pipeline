module "infra-setup" {
  source      = "./src/case-ifood-infra-setup"
}

module "lambda-get" {
  source      = "./src/case-ifood-app-lambda-get"
}

module "lambda-ingest" {
  source      = "./src/case-ifood-app-lambda-ingest"
}

module "glue-sot-rides" {
  source      = "./src/case-ifood-app-glue-tbsot_yellow_rides"
}

module "event-sor-tripdata" {
  source      = "./src/case-ifood-infra-event-call-tbsor_yellow_tripdata"
}

module "event-sot-rides" {
  source      = "./src/case-ifood-infra-event-call-tbsot_yellow_rides"
}