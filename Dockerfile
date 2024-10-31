ARG BUILD_FROM=alpine:3.20

FROM $BUILD_FROM

ARG \
	TARGETPLATFORM="linux/amd64" \
	S6_OVERLAY_VERSION=3.2.0.2 \
	S6_SRC=https://github.com/just-containers/s6-overlay/releases/download \
	S6_DIR=/etc/s6-overlay/s6-rc.d \
	GEM_FILE=https://raw.githubusercontent.com/alexandrecuer/sharebox/refs/heads/master/src/Gemfile \
	PRIMOS="postgres"

RUN apk update && apk upgrade;\
	apk add --no-cache nodejs;\
	apk add --no-cache ruby;\
	apk add --no-cache ruby-dev;\
	apk add --no-cache ruby-bundler;\
	apk add --no-cache postgresql16;\
	apk add --no-cache postgresql-common;\
	apk add --no-cache libpq-dev;\
	apk add --no-cache imagemagick;\
	apk add --no-cache tzdata xz bash git make tar;\
	apk add --no-cache ca-certificates wget

RUN set -x;\
	apk add --no-cache build-base;\
	gem install rails;\
	wget $GEM_FILE;\
	bundle install;\
	apk del --no-cache build-base

RUN set -x;\
	mkdir -p /data;\
	mkdir -p /run/postgresql;\
	chown -R postgres /run/postgresql

RUN apk add --no-cache sqlite;\
	apk add --no-cache nano

RUN set -x;\
	case $TARGETPLATFORM in \
	"linux/amd64")  S6_ARCH="x86_64"  ;; \
	"linux/arm/v7") S6_ARCH="arm"  ;; \
	"linux/arm64") S6_ARCH="aarch64"  ;; \
	esac;\
	wget -P /tmp $S6_SRC/v$S6_OVERLAY_VERSION/s6-overlay-$S6_ARCH.tar.xz --no-check-certificate;\
	wget -P /tmp $S6_SRC/v$S6_OVERLAY_VERSION/s6-overlay-noarch.tar.xz --no-check-certificate;\
	tar -C / -Jxpf /tmp/s6-overlay-$S6_ARCH.tar.xz;\
	tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz

COPY colibri_pre.sh sql_ready.sh exec_cmd.sh ./

RUN set -x;\
	# oneshot service called colibri_pre
	mkdir $S6_DIR/colibri_pre;\
	mkdir $S6_DIR/colibri_pre/dependencies.d;\
	touch $S6_DIR/colibri_pre/dependencies.d/base;\
	echo "oneshot" > $S6_DIR/colibri_pre/type;\
	echo "/colibri_pre.sh" > $S6_DIR/colibri_pre/up;\
	touch $S6_DIR/user/contents.d/colibri_pre;\
	# start primo services after colibri_pre
	for i in $PRIMOS; do mkdir $S6_DIR/$i; done;\
	for i in $PRIMOS; do mkdir $S6_DIR/$i/dependencies.d; done;\
	for i in $PRIMOS; do touch $S6_DIR/$i/dependencies.d/colibri_pre; done;\
	for i in $PRIMOS; do touch $S6_DIR/user/contents.d/$i; done;\
	for i in $PRIMOS; do echo "longrun" > $S6_DIR/$i/type; done;\
	for i in $PRIMOS; do echo "#!/command/execlineb -P" > $S6_DIR/$i/run; done;\
	echo "s6-setuidgid postgres" >> $S6_DIR/postgres/run;\
	echo "postgres -D /data/pgsql" >> $S6_DIR/postgres/run;\
	chmod +x colibri_pre.sh;\
	chmod +x exec_cmd.sh

RUN set -x;\
	# check if SQL is fully ready with a oneshot service
	mkdir $S6_DIR/sql_ready;\
	mkdir $S6_DIR/sql_ready/dependencies.d;\
	touch $S6_DIR/sql_ready/dependencies.d/legacy-services;\
	echo "oneshot" > $S6_DIR/sql_ready/type;\
	echo "/sql_ready.sh" > $S6_DIR/sql_ready/up;\
	touch $S6_DIR/user2/contents.d/sql_ready;\
	chmod +x sql_ready.sh

ENV \
	S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
	S6_SERVICES_GRACETIME=18000

ENV \
	TZ="Europe/Paris" \
	GMAIL_USERNAME=your_email \
	GMAIL_PASSWORD=your_sendgrid_api_key \
	SMTP_ADDRESS="smtp.sendgrid.net" \
	SMTP_PORT=587 \
	DOMAIN=localhost \
	DB_USER_NAME=colibri \
	DB_USER_PASS=Taxo10in2019* \
	AWS_REGION=eu-west-3 \
	AWS_ACCESS_KEY_ID=your_access_key \
	AWS_SECRET_ACCESS_KEY=your_secret_access_key \
	S3_BUCKET_NAME=colibri
	

EXPOSE 3000

ENTRYPOINT ["/init"]

