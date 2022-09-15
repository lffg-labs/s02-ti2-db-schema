-- cspell:words frello

CREATE SCHEMA IF NOT EXISTS frello;

-- The `user` relation is self-descriptive.
CREATE TABLE IF NOT EXISTS frello.users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    username varchar(32) NOT NULL UNIQUE,

    first_name varchar(256) NOT NULL,
    last_name varchar(256) NOT NULL,

    is_consumer boolean NOT NULL DEFAULT true,
    is_provider boolean NOT NULL DEFAULT false,
    is_admin boolean NOT NULL DEFAULT false,

    -- Soft deletion.
    is_deleted boolean NOT NULL DEFAULT false,
    deletion_time timestamptz DEFAULT null,
    -- Other metadata.
    creation_time timestamptz DEFAULT now()
);

-- The `provider_category` contains categories of work services available to be
-- performed in the platform.
CREATE TABLE IF NOT EXISTS frello.work_service_categories (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),


    pretty_label varchar(512) NOT NULL,
    -- Derived from `pretty_label`.
    label_slug varchar(256) NOT NULL UNIQUE,

    -- N.b. use the `yiq` npm package to set the CSS `color` property. ;D
    hex_css_color varchar(6) NOT NULL DEFAULT '000000'
);

-- The `provider_work_service_pages` relation provides a page where the provider
-- user can announce its services. The page also lists the previously services
-- that the provider has performed.
CREATE TABLE IF NOT EXISTS frello.provider_work_service_pages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id uuid NOT NULL REFERENCES frello.users(id),

    category_id uuid NOT NULL REFERENCES frello.work_service_categories(id),

    page_title text NOT NULL,
    -- Derived from `page_title`.
    page_title_slug varchar(256) NOT NULL UNIQUE,

    raw_markdown_page_body text NOT NULL,
    -- Not to be edited directly—it should derive from the markdown processing!
    parsed_page_body text NOT NULL,

    -- Soft deletion.
    is_deleted boolean NOT NULL DEFAULT false,
    deletion_time timestamptz DEFAULT null,
    -- Other metadata.
    creation_time timestamptz DEFAULT now()
);

-- See next relation (i.e. `service`) to reason about this type.
CREATE TYPE frello.work_service_state AS ENUM (
    'in_progress',
    'completed',
    'withdrawn'
);

-- The `work service` relation provider a binary relation from two users, a
-- provider (which executes the service) and a consumer (which contracts the
-- provider).
CREATE TABLE IF NOT EXISTS frello.work_services (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    state frello.work_service_state NOT NULL DEFAULT 'in_progress',

    page_id uuid NOT NULL REFERENCES frello.provider_work_service_pages(id),
    provider_id uuid NOT NULL REFERENCES frello.users(id),
    consumer_id uuid NOT NULL REFERENCES frello.users(id),

    -- Soft deletion.
    is_deleted boolean NOT NULL DEFAULT false,
    deletion_time timestamptz DEFAULT null,
    -- Other metadata.
    creation_time timestamptz DEFAULT now()
);

-- The `work_service_message` represents a conversation visible in a work
-- service page. A message can not be updated or deleted.
CREATE TABLE IF NOT EXISTS frello.work_service_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Message author.
    author_id uuid NOT NULL REFERENCES frello.users(id),
    -- The service on which this message is associated.
    work_service_id uuid NOT NULL REFERENCES frello.work_services(id),

    raw_markdown_message text NOT NULL,
    -- Not to be edited directly—it should derive from the markdown processing!
    parsed_html_message text NOT NULL,

    -- Other metadata.
    creation_time timestamptz DEFAULT now()
);

-- The relation `provider_page_consumer_review` provides a review, visible on
-- the `provider_work_service_pages` page.
CREATE TABLE IF NOT EXISTS frello.provider_page_consumer_review (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    -- The review author.
    author_id uuid NOT NULL REFERENCES frello.users(id),
    -- The corresponding service and its provider:
    work_service_id uuid NOT NULL REFERENCES frello.work_services(id),
    provider_id uuid NOT NULL REFERENCES frello.users(id),

    -- Review percentage score.
    review_score int NOT NULL,

    CONSTRAINT is_valid_review_percentage
        CHECK (0 <= review_score AND review_score <= 100),

    raw_markdown_body text NOT NULL,
    -- Not to be edited directly—it should derive from the markdown processing!
    parsed_body text NOT NULL,

    -- Soft deletion.
    is_deleted boolean NOT NULL DEFAULT false,
    deletion_time timestamptz DEFAULT null,
    -- Other metadata.
    creation_time timestamptz DEFAULT now()
);

-- The `admin_logs` relation is self-descriptive.
CREATE TABLE IF NOT EXISTS frello.admin_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id uuid NOT NULL REFERENCES frello.users(id),
    message text NOT NULL
);
